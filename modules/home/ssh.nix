{ lib, pkgs, ... }:
{
  # Home-manager ssh config
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      forwardAgent = true;
      addKeysToAgent = "yes";
      sendEnv = [
        "JUSPAY_*"
        "GITHUB_*"
        "ANTHROPIC_*"
        "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS"
      ];
    };
  };
  # To avoid collision in home-manager
  # see: https://github.com/nix-community/home-manager/issues/4199
  home.file.".ssh/config".force = true;
  services.ssh-agent = lib.mkIf pkgs.stdenv.isLinux { enable = true; };
}
