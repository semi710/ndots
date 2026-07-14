# Shared cloud server configuration for Oracle VPS hosts (obox, bbox).
{ hostName }:
{
  flake,
  modulesPath,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = import (flake + "/config.nix");
  me = cfg.users.me;
  username = cfg.users.${hostName}.username;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    flake.inputs.disko.nixosModules.disko
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.nix-index-database.nixosModules.nix-index
    flake.flakeModules.nix
    flake.nixosModules.tailscale
    flake.nixosModules.beszel
    flake.nixosModules.virtualisation

    # Shorthand: config.hm.* -> config.home-manager.users.${username}.*
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" username ])
  ];

  networking.hostName = hostName;

  home-manager.sharedModules = [
    {
      home.stateVersion = "26.05";
      disabledModules = [ "${flake}/modules/home/shell/android.nix" ];
      home.shellAliases.fetch = lib.mkForce "";
    }
    flake.homeModules.naste
  ];
  home-manager.backupFileExtension = "backup";

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  environment.variables.TERM = "xterm-256color";

  networking.firewall.allowedTCPPorts = [
    80
    443
    3090
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/server.yaml";
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = me.sshPublicKeys;
    shell = pkgs.zsh;
  };
  users.users.root.openssh.authorizedKeys.keys = me.sshPublicKeys;

  sops.secrets."tailscale_auth_key" = { };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;

  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 3090;
    environment.APP_URL = "https://beszel.semi.sh";
  };

  users.groups.beszel-hub-key = { };

  sops.secrets."beszel/ssh_key" = {
    group = "beszel-hub-key";
    mode = "0440";
  };
  sops.secrets."beszel/username" = {
    group = "beszel-hub-key";
    mode = "0440";
  };
  sops.secrets."beszel/password" = {
    group = "beszel-hub-key";
    mode = "0440";
  };
  sops.secrets."beszel/token" = {
    group = "beszel-token";
    mode = "0440";
  };

  sops.templates."beszel-hub-env" = {
    content = ''
      USER_EMAIL=${config.sops.placeholder."beszel/username"}
      USER_PASSWORD=${config.sops.placeholder."beszel/password"}
    '';
    group = "beszel-hub-key";
    mode = "0440";
  };

  services.beszel.hub.environmentFile = config.sops.templates."beszel-hub-env".path;
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
  services.beszel.agent.user = username;

  systemd.services.beszel-hub = {
    serviceConfig.SupplementaryGroups = [ "beszel-hub-key" ];
    preStart = lib.mkBefore ''
      cp "${config.sops.secrets."beszel/ssh_key".path}" /var/lib/beszel-hub/beszel_data/id_ed25519
      chmod 0600 /var/lib/beszel-hub/beszel_data/id_ed25519
    '';
  };

  services.caddy = {
    enable = true;
    configFile = "/etc/caddy/Caddyfile";
    enableReload = true;
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
