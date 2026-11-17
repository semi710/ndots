{
  flake,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    flake.homeModules.default
    flake.homeModules.ai
    flake.homeModules.stylix
  ];
  stylix.cliOnly = true;

  # claude code is configured on the Windows host - keep HM out of ~/.claude
  # (the ai module enables it and renders settings.json/CLAUDE.md/skills)
  s-ai.agents.claude.enable = lib.mkForce false;

  home.username = "dell";
  home.packages = [ pkgs.git ];
  # git config is symlinked in from the Windows host - keep HM off it entirely
  # (the shared shell module enables programs.git, which writes ~/.gitconfig)
  programs.git.enable = lib.mkForce false;
  # non-NixOS integration: sources nix.sh, fixes XDG dirs, and exports
  # TERMINFO_DIRS into the profile so Ubuntu's clear/tmux find xterm-kitty
  # (mkHomeConfigs builds this file for darwin systems too - keep it inert there)
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
  programs.zsh.initContent = ''
    export ZSH_DISABLE_COMPFIX="true"
  '';
}
