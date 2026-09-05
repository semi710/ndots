# Home-manager config for nikhil on bbox.
{
  flake,
  config,
  ...
}:
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.nix-index
    flake.homeModules.sops
  ];
  programs.ssh.settings."*".forwardAgent = false;

  sops.secrets = {
    "naste/user" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
    "naste/pass" = {
      sopsFile = "${flake}/secrets/server.yaml";
    };
  };

  programs.naste-client.private = {
    userFile = config.sops.secrets."naste/user".path;
    passFile = config.sops.secrets."naste/pass".path;
  };
}
