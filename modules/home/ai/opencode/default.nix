# Opencode — agent config, providers, TUI, plugins.
{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  ponytail = inputs.ponytail;
  combinedSystemPrompt = import ../combined-system-prompt.nix { inherit lib; };
  skillsMod = import ./skills.nix { inherit inputs lib; };
  registryFiles = import ./registry.nix { inherit inputs lib; };
in
{
  home.sessionVariables.OPENCODE_ENABLE_EXA = 1;
  home.file = registryFiles // skillsMod.files;

  programs.opencode = {
    enable = true;
    package = pkgs.opencode-vim;
    enableMcpIntegration = true;
    web = {
      enable = lib.mkDefault false;
      extraArgs = [ "--mdns" ];
    };
    settings = {
      default_agent = "OpenAgent";
      autoupdate = true;
      plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];
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
      agent.OpenAgent = {
        prompt = combinedSystemPrompt;
        skills = skillsMod.skills;
      };
    };
    tui = {
      vim_system_clipboard_register = true;
      vim_escape_sequence = "jk";
      vim_enter_submit = true;
      vim_insert_after_submit = true;
    };
  };
}
