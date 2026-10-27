# AI agents via the s-ai flake (path:../s-ai): skills, prompts, MCP and
# provider renders live there. This file supplies only the ndots-specific
# config: the juspay grid, the stylix palette, the workmux and
# understand-anything skill sets, the pi clipboard tool, and the personal
# opencode-only providers.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # work tier, gated per host - merged into s-ai's canonical set
  workServers = {
    github = {
      command = lib.getExe pkgs.github-mcp-server;
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
in
{
  imports = [ inputs.s-ai.homeModules.s-ai ];

  options.ndots.ai.mcp.workServers =
    lib.mkEnableOption "work-specific MCP servers (github, newton-hs-prod)";

  config = {
    home.packages = [
      pkgs.openspec
      # nix LSP - omp auto-detects it from flake.nix root markers and wires
      # diagnostics/imports into edits; other agents resolve from project bins/PATH
      pkgs.nil
    ];

    # universal plugin root the understand-dashboard skill resolves (same
    # symlink the upstream installer creates); read-only store path is fine,
    # the dashboard runs from a prebuilt npx tarball
    home.file.".understand-anything-plugin".source =
      "${inputs.understand-anything}/understand-anything-plugin";

    s-ai = {
      providers.juspay = {
        baseUrl = "https://grid.ai.juspay.net";
        apiKeyEnv = "JUSPAY_API_KEY";
        # attrsets pin each served model's real window so omp's context meter and
        # compaction match the grid. windows/maxTokens are what the grid
        # advertises on `GET /v1/models` (max_input_tokens / max_output_tokens);
        # if the grid's routing changes, re-check that endpoint. this is the
        # authoritative source - omp's own 128k fallback is wrong for these.
        models = [
          {
            id = "open-large";
            contextWindow = 400000;
            maxTokens = 32000;
          }
          {
            id = "open-fast";
            contextWindow = 256000;
            maxTokens = 32000;
          }
          {
            id = "claude-opus-4-5";
            contextWindow = 1000000;
            maxTokens = 128000;
          }
          {
            id = "claude-opus-4-6";
            contextWindow = 1000000;
            maxTokens = 128000;
          }
          {
            id = "claude-sonnet-4-6";
            contextWindow = 200000;
            maxTokens = 64000;
          }
          {
            id = "claude-sonnet-4-5";
            contextWindow = 200000;
            maxTokens = 64000;
          }
          {
            id = "gemini-3.1-pro";
            contextWindow = 1048576;
            maxTokens = 65536;
          }
          {
            id = "glm-flash-experimental";
            contextWindow = 128000;
            maxTokens = 128000;
          }
          {
            id = "glm-latest";
            contextWindow = 1000000;
            maxTokens = 32000;
          }
          {
            id = "kimi-latest";
            contextWindow = 256000;
            maxTokens = 32000;
          }
          {
            id = "kimi-k3";
            contextWindow = 256000;
            maxTokens = 32000;
          }
        ];
        defaultModel = "glm-latest";
      };
      defaultProvider = "juspay";

      # omp theme follows the system scheme (kanagawa-dragon via stylix);
      # s-ai filters to the base16 keys itself
      theme.palette = config.lib.stylix.colors;

      # worktree/tmux workflow skills (off by default in s-ai, on for us)
      plugins.workmux.enable = true;

      # Understand Anything (/understand* skills): vendored skills that ship
      # scripts + subdirs, so whole-dir symlinks; opencode + pi, as before
      # the s-ai move
      plugins.understand-anything = {
        enable = true;
        skills.dir = "${inputs.understand-anything}/understand-anything-plugin/skills";
        skills.agents = [
          "opencode"
          "pi"
        ];
        skills.symlinkDirs = true;
      };

      # vim-motions-pi OSC 52 yank via our copy tool
      agents.pi.clipboardCommand = lib.getExe pkgs.copy;

      # advisor/prewalk roles point at grid models explicitly; omp's builtin
      # fallback chains carry none, which would leave the roles unarmed
      agents.omp.advisorModel = "juspay/claude-sonnet-4-6";
      agents.omp.smolModel = "juspay/glm-flash-experimental";

      mcp.servers = lib.mkIf config.ndots.ai.mcp.workServers workServers;
    };

    # opencode-only providers (built-in gateways / env keys), not part of the
    # shared grid; s-ai does not manage these
    programs.opencode.settings = {
      provider.opencode.options.apiKey = "{env:OPENCODE_API_KEY}";
      provider.openrouter.options.apiKey = "{env:OPENROUTER_API_KEY}";
      provider.anthropic.models = {
        claude-opus-4-7 = {
          id = "claude-opus-4-7";
          name = "gawwd";
        };
        claude-sonnet-4-6 = {
          id = "claude-sonnet-4-6";
          name = "worker";
        };
        claude-haiku-4-5 = {
          id = "claude-haiku-4-5";
          name = "haiya";
        };
      };
    };
  };
}
