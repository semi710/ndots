{
  flake,
  lib,
  pkgs,
  config,
  ...
}:
let
  me = (import (flake + "/config.nix")).me // {
    username = "nikhil.singh";
  };
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.nixosModules.default

    flake.nixosModules.office
    flake.inputs.sops-nix.nixosModules.sops

    # Important for the hardware
    flake.inputs.disko.nixosModules.disko
    ./disk.nix
    # should be generated sudo nixos-generate-config --show-hardware-config --root /mnt > ./hosts/nixos/{host}/hardware.nix>
    ./hardware.nix
    # extra-users added in the system
    ./extra-users.nix
  ];

  environment.variables = {
    TERM = "xterm-256color";
    ZSH_DISABLE_COMPFIX = "true";
  };

  programs.zsh.enable = true;
  # Primary user setup
  users = {
    defaultUserShell = pkgs.zsh;
    groups.extra = { };
    users.${me.username} = {
      name = me.username;
      home = "/home/${me.username}";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "extra"
        "docker"
      ];
      openssh.authorizedKeys.keys = me.sshPublicKeys ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSq2XkQgBVoDLjvh7X1ULsDIfCrRcn4HM3un2uzUUIM nix-builder@ndots"
      ];
    };
  };

  services.tailscale.enable = true;
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

  # System-wide known hosts so nix-daemon (root) can SSH to builders
  programs.ssh.knownHosts = {
    semi = {
      hostNames = [
        "semi"
        "semi.persian-vega.ts.net"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9zAGumywN507wgOwNoGKjJkr5dn/TFejM7FAiKdHvg";
    };
  };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  networking = {
    stevenblack.enable = true;
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [ me.username ];

  # System-level sops for nix builder SSH key
  sops = {
    age.keyFile = "/home/${me.username}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/office.yaml";
    secrets."private-keys/nix-builder" = {
      owner = "root";
      group = "root";
      mode = "0600";
      path = "/root/.ssh/nix-builder";
    };
  };

  # Home-manager still manages nix_access_token
  hm.sops.secrets."private-keys/nix_access_token" = {
    sopsFile = "${flake}/secrets/office.yaml";
  };
  nix.extraOptions = # conf
    ''
      !include ${config.hm.sops.secrets."private-keys/nix_access_token".path}
    '';

  # Remote builders
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "semi";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
      sshUser = "nikhil.singh";
      sshKey = config.sops.secrets."private-keys/nix-builder".path;
    }
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = "25.11";
}
