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
      # gateway intermittently 403s; keep-alive's 30s health-check retry loop
      # spams errors for the whole outage - connect on tool use instead
      lifecycle = "lazy";
    };
  };

  servers = universalServers // workServers;

  # omp's mcp.json schema is strict (additionalProperties: false): stdio takes
  # command/args/env, http takes type/url/headers. Strip the pi-only keys
  # (lifecycle, directTools, autoApprove) and translate `{env:VAR}` values to
  # omp's env-name form.
  ompServer =
    server:
    let
      env = lib.mapAttrs (_: v: lib.removeSuffix "}" (lib.removePrefix "{env:" v)) (
        lib.filterAttrs (_: v: v != null) (server.env or { })
      );
    in
    if (server.type or "stdio") == "stdio" then
      {
        inherit (server) command;
      }
      // lib.optionalAttrs (server.args or [ ] != [ ]) { inherit (server) args; }
      // lib.optionalAttrs (env != { }) { inherit env; }
    else
      {
        type = "http";
        url = server.url;
      }
      // lib.optionalAttrs ((server.headers or { }) != { }) { inherit (server) headers; };
in
{
  options.ndots.ai.mcp.workServers =
    lib.mkEnableOption "work-specific MCP servers (github, newton-hs-prod)";

  config = {
    programs.mcp = {
      enable = true;
      inherit servers;
    };

    # render omp's mcp.json ourselves, from the same merged programs.mcp.servers
    # set as opencode (host-level additions like bitbucket land in omp too).
    # omp reads it read-only, a store symlink is fine.
    home.file.".omp/agent/mcp.json" = lib.mkIf config.programs.omp.enable {
      text = builtins.toJSON {
        mcpServers = lib.mapAttrs (_: ompServer) config.programs.mcp.servers;
      };
    };
  };
}
