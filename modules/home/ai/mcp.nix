{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';

  servers' = {
    git.command = getExe pkgs.mcp-server-git;
    fetch.command = getExe pkgs.mcp-server-fetch;
    sequential-thinking.command = getExe' pkgs.mcp-server-sequential-thinking "mcp-server-sequential-thinking";
    github = {
      command = getExe pkgs.github-mcp-server;
      args = [ "stdio" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_TOKEN}";
    };
    everything = {
      command = getExe pkgs.mcp-server-filesystem;
      args = [ "${config.home.homeDirectory}" ];
    };
    # context7 = {
    #   type = "remote";
    #   url = "https://mcp.context7.com/mcp";
    #   headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
    # };
    gitnexus = {
      command = getExe pkgs.llm-agents.gitnexus;
      args = [ "mcp" ];
    };
    playwright.command = getExe pkgs.playwright-mcp;
    newton-hs-prod = {
      autoApprove = [
        "search_functions_by_keyword"
        "query_to_function_meta_data"
      ];
      type = "http";
      url = "https://juspay-brain.internal.svc.k8s.office.mum.juspay.net/newton-hs/";
    };
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
in
{
  programs.mcp = {
    enable = true;
    servers = lib.mapAttrs (_: server: { lifecycle = "eager"; } // server) servers';
  };
}
