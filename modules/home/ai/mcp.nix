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
  };

  # Work-specific - only included when workServers is enabled
  workServers = lib.optionalAttrs cfg.workServers {
    github = {
      command = getExe pkgs.github-mcp-server;
      args = [ "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_TOKEN}";
    };
    gitnexus = {
      command = getExe pkgs.llm-agents.gitnexus;
      args = [ "mcp" ];
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
    lib.mkEnableOption "work-specific MCP servers (github, gitnexus, newton-hs-prod)";

  config = {
    programs.mcp = {
      enable = true;
      inherit servers;
    };
  };
}
