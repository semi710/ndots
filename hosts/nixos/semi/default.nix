{ flake, config, ... }:
{
  imports = [
    ../common/workstation.nix
    ./disk.nix
    ./hardware.nix
    ./extra-users.nix
    flake.nixosModules.beszel
  ];

  sops.secrets."private-keys/beszel_u_token" = {
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE =
    config.sops.secrets."private-keys/beszel_u_token".path;
}
