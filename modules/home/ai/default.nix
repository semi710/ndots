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
        # grid serves both wire protocols (/v1/chat/completions and
        # /v1/messages); anthropic feeds claude code
        protocols = [
          "openai"
          "anthropic"
        ];
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

      # claude code, speaking anthropic to the grid (unfree package allowed
      # by nix-wire's blanket allowUnfree on every entrypoint)
      agents.claude.enable = true;

      # vim-motions-pi OSC 52 yank via our copy tool
      agents.pi.clipboardCommand = lib.getExe pkgs.copy;

      # vim-style transcript copy mode (ctrl+x to enter, v/j/k/y to select/copy)
      agents.pi.copyMode = true;

      # pi extensions, version-pinned npm specs (pi update leaves pinned specs)
      agents.pi.extraPackages = [
        "npm:pi-web-access@0.46.0" # search + fetch + YouTube
        "npm:pi-lens@4.4.8" # LSP/lint/diagnostics on edits
        "npm:pi-subagents@0.84.0" # in-session child agents
        "npm:@juicesharp/rpiv-todo@2.15.0" # live todo panel, survives compaction
        "npm:@juicesharp/rpiv-ask-user-question@2.15.0" # structured questions to you
      ];

      # advisor/prewalk roles point at grid models explicitly; omp's builtin
      # fallback chains carry none, which would leave the roles unarmed
      agents.omp.advisorModel = "juspay/claude-opus-4-6";
      agents.omp.smolModel = "juspay/glm-flash-experimental";

      mcp.servers = lib.mkIf config.ndots.ai.mcp.workServers workServers;
    };

    # v2 terminal-client prefs, rendered into cli.json by the s-ai module
    # (tabs off per the top-bar question; the rest mirrors what the Nov-4
    # auto-migration had baked in)
    # stylix pins the v1 tui theme, which OpenCode 2 ignore-warns on; the
    # s-ai module reads the theme from themes.stylix for cli.json instead
    programs.opencode.tui = lib.mkForce { };

    s-ai.agents.opencode.extraCliSettings = {
      tabs.mode = "off";
      diffs.wrap = "word";
      session = {
        sidebar = "hide";
        scrollbar = false;
        thinking = "show";
      };
      animations = true;
      # image paste (ctrl+v) works since the ocv 2.3.0 bump; clipboard
      # read errors are now surfaced instead of silently dropped
      # (upstream #62181 was the silent-failure, #61094 added error display)
      # ctrl+alt+k is the upstream default but unsendable from macOS
      # terminals; <leader>k (ctrl+x, k) is the alternative. keep both
      # so the leader path works when vim mode's jk-escape doesn't eat
      # the k first. keybind entries must stay flat dotted keys.
      keybinds."which-key.toggle" = "<leader>k,ctrl+alt+k";
      keybinds."help.show" = "f1";
    };

    # opencode's TUI rewrites cli.json in place (settings dialog, env
    # content merges), replacing the store symlink with a regular file;
    # force keeps the next deploy from wedging on the backup collision
    home.file.".config/opencode/cli.json".force = true;

    # v2 permission rules, ordered, LAST match wins. s-ai still renders the
    # v1 `permission` map whose "*": "ask" sits last, so after v2's in-memory
    # normalization it silently overrode every allow and asked for
    # everything. Native v2 rules take precedence over the v1 map, so the
    # blanket ask leads here and the specific allows land after it.
    # A trailing " *" pattern also matches the bare command (v2 rule).
    # git is allowed wholesale; the ask carve-outs after the allow list
    # re-gate the publishing/irreversible commands (last match wins).
    s-ai.agents.opencode.extraSettings.permissions = [
      {
        action = "shell";
        resource = "*";
        effect = "ask";
      }
    ]
    ++
      map
        (pattern: {
          action = "shell";
          resource = pattern;
          effect = "allow";
        })
        [
          "git *"
          "ls *"
          "cat *"
          "head *"
          "tail *"
          "wc *"
          "tree *"
          "find *"
          "file *"
          "stat *"
          "readlink *"
          "realpath *"
          "which *"
          "echo *"
          "pwd *"
          "basename *"
          "dirname *"
          "test *"
          "true"
          "false"
          "nix *"
          "nix-instantiate *"
          "python3 -m json.tool *"
          "jq *"
          "ps *"
          "rg *"
          "grep *"
          "fd *"
          "awk *"
          "sed *"
          "cut *"
          "tr *"
          "nl *"
          "sort *"
          "uniq *"
          "diff *"
          "less *"
          "xxd *"
          "strings *"
          "du *"
          "df *"
          "date *"
          "uname *"
          "sw_vers *"
          "hostname *"
          "id *"
          "whoami *"
          "printenv *"
          "env"
          "mkdir *"
          "touch *"
          "sleep *"
          "seq *"
          "base64 *"
          "sha256sum *"
          "md5sum *"
          "bat *"
          "eza *"
          "curl *"
          "ping *"
          "dig *"
        ]
    ++
      map
        (pattern: {
          action = "shell";
          resource = pattern;
          effect = "ask";
        })
        [
          "git push *"
          "git commit *"
          "git reset --hard *"
          "git clean *"
          # nix wholesale is allowed above; keep profile mutations (AGENTS.md
          # says never profile install) and destructive/publishing ops gated
          "nix profile *"
          "nix store gc *"
          "nix store delete *"
          "nix copy *"
        ]
    ++ [
      {
        action = "read";
        resource = "*";
        effect = "allow";
      }
      {
        action = "read";
        resource = ".env*";
        effect = "ask";
      }
      {
        action = "read";
        resource = "**/.env*";
        effect = "ask";
      }
      {
        action = "grep";
        resource = "*";
        effect = "allow";
      }
      {
        action = "grep";
        resource = ".env*";
        effect = "ask";
      }
      {
        action = "grep";
        resource = "**/.env*";
        effect = "ask";
      }
      {
        action = "glob";
        resource = "*";
        effect = "allow";
      }
    ];

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
