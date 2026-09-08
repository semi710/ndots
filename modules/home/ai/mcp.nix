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
    nixos = {
      command = "nix";
      args = [
        "run"
        "github:utensils/mcp-nixos"
        "--"
      ];
    };
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
    };
  };

  servers = universalServers // workServers;
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
    # read from config.programs.mcp.servers so host-level additions (e.g.
    # bitbucket in workstation.nix) land in pi too, same as opencode.
    # nulls are the mcp module's option defaults for unset fields - strip them,
    # pi's own config format omits them.
    home.file.".pi/agent/mcp.json" = lib.mkIf config.programs.pi-coding-agent.enable {
      text = builtins.toJSON {
        # 111 direct tools is deliberate; silence the adapter's token-cost advisory
        # that re-prints on every keep-alive catalog refresh
        settings.warnOnLargeDirectTools = false;
        mcpServers = lib.mapAttrs (
          _: server:
          lib.filterAttrs (_: v: v != null) (
            server
            // {
              lifecycle = "keep-alive";
              directTools = true;
            }
          )
        ) config.programs.mcp.servers;
      };
    };
  };
}
