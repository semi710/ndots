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
