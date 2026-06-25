# Beszel hub on Oracle Cloud (obox).
# Server config — hub + shell + SSH + networking + tailscale + sops + docker.
{
  flake,
  modulesPath,
  pkgs,
  lib,
  config,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me;
  username = "nikhil";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    flake.inputs.disko.nixosModules.disko
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.nix-index-database.nixosModules.nix-index
    ./disk.nix
    ./hardware.nix
    flake.flakeModules.nix
    flake.nixosModules.tailscale
    flake.nixosModules.beszel
    flake.nixosModules.virtualisation
    flake.nixosModules.filebrowser

    # Shorthand: config.hm.* → config.home-manager.users.${username}.*
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" username ])
  ];

  home-manager.sharedModules = [ { home.stateVersion = "26.05"; } ];
  home-manager.backupFileExtension = "backup";

  # One-time setup after a fresh hub DB: enable the universal token so agents
  # can self-register. Login to get a JWT, then GET with query params:
  #   JWT=$(curl -s http://localhost:3090/api/collections/users/auth-with-password \
  #     -H "Content-Type: application/json" \
  #     -d '{"identity":"<email>","password":"<pass>"}' | jq -r .token)
  #   curl "http://localhost:3090/api/beszel/universal-token?enable=1&permanent=1&token=<token>" \
  #     -H "Authorization: $JWT"
  # Token value is in secrets/server.yaml under beszel.token.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 3090;
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

  # sops.templates composes the env file at activation time.
  # Placeholders are replaced with actual secret values (not paths).
  sops.templates."beszel-hub-env" = {
    content = ''
      USER_EMAIL=${config.sops.placeholder."beszel/username"}
      USER_PASSWORD=${config.sops.placeholder."beszel/password"}
    '';
    group = "beszel-hub-key";
    mode = "0440";
  };

  services.beszel.hub.environmentFile = config.sops.templates."beszel-hub-env".path;

  systemd.services.beszel-hub = {
    serviceConfig.SupplementaryGroups = [ "beszel-hub-key" ];
    preStart = lib.mkBefore ''
      cp "${config.sops.secrets."beszel/ssh_key".path}" /var/lib/beszel-hub/beszel_data/id_ed25519
      chmod 0600 /var/lib/beszel-hub/beszel_data/id_ed25519
    '';
  };

  # Stirling PDF — NixOS native service
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 4080;
      UI_APPNAME = "semi.sh PDF";
      UI_HOMEDESCRIPTION = "Privacy-first PDF tools, hosted on semi.sh";
      UI_APPNAVBARNAME = "semi.sh PDF";
      SYSTEM_SHOWUPDATE = "false";
      SYSTEM_SHOWUPDATEONLYADMIN = "false";
    };
  };

  services.filebrowser-quantum = {
    enable = true;
    home = "/home/${username}";
  };
  sops.secrets."filebrowser/obox" = { };
  services.filebrowser-quantum.passwordFile = config.sops.secrets."filebrowser/obox".path;

  services.caddy = {
    enable = true;
    configFile = "/etc/caddy/Caddyfile";
    enableReload = true;
  };

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
    secrets."tailscale_auth_key" = { };
    secrets."beszel/token" = {
      group = "beszel-token";
      mode = "0440";
    };
  };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;

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

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";
}
