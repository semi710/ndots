# Shared workstation configuration for Juspay work machines (dsd, semi)
{
  flake,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = import (flake + "/config.nix");
  me = cfg.users.me // {
    username = "nikhil.singh";
  };
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
    flake.nixosModules.default
    flake.nixosModules.juspay
    flake.inputs.sops-nix.nixosModules.sops
    flake.inputs.disko.nixosModules.disko
    flake.nixosModules.beszel
    flake.nixosModules.tailscale
    flake.nixosModules.virtualisation
    flake.nixosModules.filebrowser
  ];

  sops.secrets."beszel/token" = {
    sopsFile = "${flake}/secrets/server.yaml";
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
  services.beszel.agent.user = me.username;

  users.users.${me.username} = {
    name = me.username;
    home = "/home/${me.username}";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "extra"
      "docker"
    ];
    openssh.authorizedKeys.keys = me.sshPublicKeys ++ [ cfg.builders.key.publicKey ];
  };
  users.groups.extra = { };

  nix.settings.trusted-users = [ me.username ];

  sops = {
    age.keyFile = "${config.users.users.${me.username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = "${flake}/secrets/office.yaml";
    secrets."tailscale_auth_key" = { };
  };
  services.tailscale.authKeyFile = config.sops.secrets."tailscale_auth_key".path;

  services.filebrowser-quantum = {
    enable = true;
    home = "/home/${me.username}";
  };
  sops.secrets."filebrowser/${config.networking.hostName}" = {
    sopsFile = "${flake}/secrets/office.yaml";
  };
  services.filebrowser-quantum.passwordFile =
    config.sops.secrets."filebrowser/${config.networking.hostName}".path;

  hm.sops.secrets."private-keys/nix_access_token" = {
    sopsFile = "${flake}/secrets/office.yaml";
  };
  nix.extraOptions = "!include ${config.hm.sops.secrets."private-keys/nix_access_token".path}";

  # naste private paste creds (shared by dsd + semi)
  hm.sops.secrets."naste/user".sopsFile = "${flake}/secrets/server.yaml";
  hm.sops.secrets."naste/pass".sopsFile = "${flake}/secrets/server.yaml";
  hm.programs.naste-client.private = {
    userFile = config.hm.sops.secrets."naste/user".path;
    passFile = config.hm.sops.secrets."naste/pass".path;
  };

  # Bitbucket CLI + MCP - creds from sops (shared by all workstations)
  hm.sops.secrets."bitbucket/url".sopsFile = "${flake}/secrets/server.yaml";
  hm.sops.secrets."bitbucket/username".sopsFile = "${flake}/secrets/server.yaml";
  hm.sops.secrets."bitbucket/token".sopsFile = "${flake}/secrets/server.yaml";
  hm.home.packages = [
    (pkgs.writeShellScriptBin "bb" ''
      export BITBUCKET_URL="$(cat ${config.hm.sops.secrets."bitbucket/url".path})/rest"
      export BITBUCKET_ACCESS_TOKEN="$(cat ${config.hm.sops.secrets."bitbucket/token".path})"
      export BITBUCKET_USERNAME="$(cat ${config.hm.sops.secrets."bitbucket/username".path})"
      exec ${pkgs.bitbucket-cli}/bin/bitbucket-cli "$@"
    '')
    (pkgs.writeShellScriptBin "bitbucket-mcp" ''
      export BITBUCKET_URL="$(cat ${config.hm.sops.secrets."bitbucket/url".path})"
      export BITBUCKET_TOKEN="$(cat ${config.hm.sops.secrets."bitbucket/token".path})"
      export BITBUCKET_USERNAME="$(cat ${config.hm.sops.secrets."bitbucket/username".path})"
      exec ${pkgs.nodejs}/bin/node ${pkgs.bitbucket-mcp}/lib/bitbucket-server-mcp/build/index.js "$@"
    '')
  ];
  hm.programs.mcp.servers.bitbucket.command = "${config.hm.home.profileDirectory}/bin/bitbucket-mcp";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  # Known hosts for remote builds — both workstations know about each other
  programs.ssh.knownHosts = {
    dsd = {
      inherit (cfg.builders.dsd) hostNames;
      publicKey = cfg.builders.dsd.hostPublicKey;
    };
    semi = {
      inherit (cfg.builders.semi) hostNames;
      publicKey = cfg.builders.semi.hostPublicKey;
    };
  };
}
