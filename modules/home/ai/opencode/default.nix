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
  skillsMod = import ./skills.nix { inherit inputs lib; };
  registryFiles = import ./registry.nix { inherit inputs lib; };
in
{
  home.sessionVariables.OPENCODE_ENABLE_EXA = 1;
  home.file = registryFiles // skillsMod.files;

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
      plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];
    };
    tui = {
      vim_system_clipboard_register = true;
      vim_escape_sequence = "jk";
      vim_enter_submit = true;
      vim_insert_after_submit = true;
    };
  };
}
