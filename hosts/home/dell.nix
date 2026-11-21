{
  flake,
  lib,
  pkgs,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me;
in
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
  # no local agent: leave SSH_AUTH_SOCK alone so a forwarded agent
  # (laptop -> obox -> Ballu) stays usable in the shell
  services.ssh-agent.enable = lib.mkForce false;
  home.packages = [ pkgs.git ];
  # HM owns ~/.gitconfig here (aliases, delta, lazygit via the shared shell
  # module); identity from config.nix so commits work out of the box
  programs.git.settings.user = {
    name = me.fullname;
    email = me.email;
  };
  # non-NixOS integration: sources nix.sh, fixes XDG dirs, and (via systemd)
  # exports TERMINFO_DIRS into the user session. The shared homeModules.default
  # also exports TERMINFO_DIRS via home.sessionVariables so plain SSH logins
  # (no systemd user session) still see xterm-kitty.
  # (mkHomeConfigs builds this file for darwin systems too - keep it inert there)
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
  programs.zsh.initContent = ''
    export ZSH_DISABLE_COMPFIX="true"
  '';
}
