{
  flake,
  lib,
  pkgs,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me // {
    username = "virt";
  };
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.nixosModules.default

    # Important for the hardware
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    # should be generated sudo nixos-generate-config --show-hardware-config --root /mnt > ./hosts/nixos/virt/hardware.nix>
    ./hardware.nix
  ];

  programs.zsh.enable = true;
  # Primary user setup
  users = {
    defaultUserShell = pkgs.zsh;
    users.${me.username} = {
      name = me.username;
      home = "/home/${me.username}";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = me.sshPublicKeys;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    extraConfig = # sshd_config
      ''
        AcceptEnv LANG LC_* JUSPAY_API_KEY ANTHROPIC_* GITHUB_* CLAUDE_*
      '';
  };

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [ me.username ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = "25.11";
}
