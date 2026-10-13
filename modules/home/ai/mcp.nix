{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';
  cfg = config.ndots.ai.mcp;

  # Always included - used in nearly every session
  universalServers = {
    git.command = getExe pkgs.mcp-server-git;
    fetch.command = getExe pkgs.mcp-server-fetch;
    sequential-thinking.command = getExe' pkgs.mcp-server-sequential-thinking "mcp-server-sequential-thinking";
    everything = {
      command = getExe pkgs.mcp-server-filesystem;
      args = [ "${config.home.homeDirectory}" ];
    };
    playwright.command = getExe pkgs.playwright-mcp;
    deepwiki = {
      type = "remote";
      url = "https://mcp.deepwiki.com/mcp";
      enabled = true;
    };
    # direct binary - `nix run github:utensils/mcp-nixos` re-evaluated the
    # flake on every opencode boot (1-15s cold)
    nixos.command = getExe pkgs.mcp-nixos;
    # parity with the servers OMA injects into opencode, so pi gets them too
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
    };
    grep_app = {
      type = "remote";
      url = "https://mcp.grep.app";
    };
    codegraph = {
      command = getExe pkgs.codegraph;
      # bare `codegraph` opens the interactive setup wizard and never answers
      # initialize, hanging pi's whole MCP startup for the 60s SDK timeout
      args = [
        "serve"
        "--mcp"
      ];
    };
  };

  # Work-specific - only included when workServers is enabled
  workServers = lib.optionalAttrs cfg.workServers {
    github = {
      command = getExe pkgs.github-mcp-server;
      args = [ "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_TOKEN}";
    };
    newton-hs-prod = {
      autoApprove = [
        "search_functions_by_keyword"
        "query_to_function_meta_data"
      ];
      type = "http";
      url = "https://juspay-brain.internal.svc.k8s.office.mum.juspay.net/newton-hs/";
      # gateway intermittently 403s; keep-alive's 30s health-check retry loop
      # spams errors for the whole outage - connect on tool use instead
      lifecycle = "lazy";
    };
  };

  servers = universalServers // workServers;

  # programs.mcp.servers is multi-client/opencode flavored; pi's builtin mcp
  # extension wants its own vocabulary, so translate per server here
  toPiServer =
    server:
    let
      dropAdapterFields = lib.filterAttrs (
        k: v:
        v != null
        && !builtins.elem k [
          "lifecycle"
          "autoApprove"
        ]
      );
      dropRemoteType = s: if s.type or null == "remote" then removeAttrs s [ "type" ] else s;
      piEnv = lib.optionalAttrs (server ? env) {
        env = lib.mapAttrs (
          _: v:
          if lib.hasPrefix "{env:" v && lib.hasSuffix "}" v then
            "\${" + lib.removeSuffix "}" (lib.removePrefix "{env:" v) + "}"
          else
            v
        ) server.env;
      };
    in
    dropRemoteType (dropAdapterFields ({ exposure = "direct"; } // server // piEnv));
in
{
  options.ndots.ai.mcp.workServers =
    lib.mkEnableOption "work-specific MCP servers (github, newton-hs-prod)";

  config = {
    programs.mcp = {
      enable = true;
      inherit servers;
    };

    # render pi's mcp.json ourselves - its onboarding-written file rots after GC.
    # reads the same merged programs.mcp.servers as opencode, so host-level
    # additions (e.g. bitbucket in workstation.nix) land in pi too.
    home.file.".pi/agent/mcp.json" = lib.mkIf config.ndots.ai.pi.enable {
      text = builtins.toJSON {
        mcpServers = lib.mapAttrs (_: toPiServer) config.programs.mcp.servers;
      };
    };
  };
}
