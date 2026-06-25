{
  flake,
  lib,
  pkgs,
  config,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me;
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.nixosModules.default
    flake.nixosModules.hardware
    # flake.nixosModules.hyprland # Includes all other home manager modules
    flake.nixosModules.filebrowser
    flake.nixosModules.beszel
    flake.nixosModules.tailscale
    flake.nixosModules.virtualisation
    flake.inputs.sops-nix.nixosModules.sops

    # Important for the hardware
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    # should be generated sudo nixos-generate-config --show-hardware-config --root /mnt > ./hosts/nixos/{host}/hardware.nix>
    ./hardware.nix
  ];
  networking.firewall = {
    allowedTCPPorts = [
      8384
      22000
    ];
    allowedUDPPorts = [ 22000 ];
  };
  services.filebrowser-quantum = {
    enable = true;
    sources = [ "/run/media/${me.username}/" ];
    home = "/home/${me.username}";
  };
  sops.secrets."filebrowser/mach" = { };
  services.filebrowser-quantum.passwordFile = config.sops.secrets."filebrowser/mach".path;

  services.getty.autologinUser = "${me.username}";

  environment.variables = {
    TERM = "xterm-256color";
    ZSH_DISABLE_COMPFIX = "true";
  };
  hm.sops.secrets.user-password = { };
  programs.zsh.enable = true;
  # Primary user setup
  users = {
    defaultUserShell = pkgs.zsh;
    groups.extra = { };
    users.${me.username} = {
      name = me.username;
      home = "/home/${me.username}";
      isNormalUser = true;
      hashedPasswordFile = config.hm.sops.secrets.user-password.path;
      extraGroups = [
        "wheel"
        "networkmanager"
        "extra"
        "docker"
      ];
      openssh.authorizedKeys.keys = me.sshPublicKeys;
    };
  };

  services.tailscale.enable = true;
  sops = {
    age.keyFile = "${config.users.users.${me.username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/server.yaml";
    secrets."tailscale_auth_key" = { };
    secrets."beszel/token" = {
      group = "beszel-token";
      mode = "0440";
    };
  };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
  services.beszel.agent.environment.DOCKER_HOST = lib.mkForce "unix:///run/user/1000/docker.sock";
  # beszel crashes reading AMD GPU sysfs (known bug). Disable GPU monitoring.
  # FIX: https://github.com/henrygd/beszel/issues/1799
  services.beszel.agent.environment.SKIP_GPU = "true";
  systemd.services.beszel-agent = {
    serviceConfig.DynamicUser = lib.mkForce false;
    serviceConfig.User = lib.mkForce me.username;
    serviceConfig.Group = lib.mkForce "beszel-token";
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
  networking = {
    stevenblack.enable = true;
    networkmanager.enable = true;
  };

  hm.sops.secrets."private-keys/nix_access_token" = { };
  nix.extraOptions = # conf
    ''
      !include ${config.hm.sops.secrets."private-keys/nix_access_token".path}
    '';

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [ me.username ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = "25.11";
}
