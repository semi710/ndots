# Opencode - runtime, TUI, plugins. Agent + model config lives in
# auto-imported siblings (agents.nix, providers/*).
{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  ponytail = inputs.ponytail;
  omoPkg = pkgs.llm-agents.oh-my-opencode;
  combinedSystemPrompt = import ../combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./skills.nix { inherit inputs lib; };
  registryFiles = import ./registry.nix { inherit inputs lib; };
  defaultModel = "litellm/glm-latest";
  omoConfig = builtins.toJSON {
    default_run_agent = "sisyphus";
    team_mode = {
      enabled = true;
      tmux_visualization = true;
    };
    agents = {
      sisyphus = {
        model = defaultModel;
      };
      metis = {
        model = defaultModel;
      };
      prometheus = {
        model = defaultModel;
      };
      atlas = {
        model = defaultModel;
      };
      hephaestus = {
        model = defaultModel;
        allow_non_gpt_model = true;
      };
      oracle = {
        model = defaultModel;
      };
      momus = {
        model = defaultModel;
      };
      explore = {
        model = defaultModel;
      };
      librarian = {
        model = defaultModel;
      };
      multimodal-looker = {
        model = defaultModel;
      };
      sisyphus-junior = {
        model = defaultModel;
      };
    };
  };
in
{
  home.sessionVariables = {
    OPENCODE_ENABLE_EXA = 1;
    PONYTAIL_DEFAULT_MODE = "ultra";
  };

  home.file =
    registryFiles
    // skillsMod.files
    // {
      ".config/opencode/AGENTS.md".text = combinedSystemPrompt;
      ".config/opencode/oh-my-openagent.jsonc".text = omoConfig;
      ".config/opencode/node_modules/oh-my-openagent".source = "${omoPkg}/lib/oh-my-opencode";
    };

  imports = inputs.nix-wire.lib.autoImportExcept ./. [
    "skills.nix"
    "registry.nix"
  ];

  programs.opencode = {
    enable = true;
    package = pkgs.opencode-vim;
    enableMcpIntegration = true;
    web = {
      enable = lib.mkDefault false;
      extraArgs = [ "--mdns" ];
    };
    settings = {
      autoupdate = true;
      permission = {
        read = {
          "*" = "allow";
          ".env*" = "ask";
          "**/.env*" = "ask";
        };
        grep = {
          "*" = "allow";
          ".env*" = "ask";
          "**/.env*" = "ask";
        };
        glob = "allow";
        list = "allow";
        bash = {
          "*" = "ask";
          "rm -rf *" = "deny";
        };
      };
      plugin = [
        "${ponytail}/.opencode/plugins/ponytail.mjs"
        "oh-my-openagent"
      ];
    };
    tui = {
      vim_system_clipboard_register = true;
      vim_escape_sequence = "jk";
      vim_enter_submit = true;
      vim_insert_after_submit = true;
      scroll_acceleration.enabled = true;
      plugin = [
        "${ponytail}/.opencode/plugins/ponytail.mjs"
        "oh-my-openagent"
      ];
    };
  };

  home.packages = [
    pkgs.llm-agents.oh-my-opencode
    pkgs.nodejs
    pkgs.bun
  ];
}
