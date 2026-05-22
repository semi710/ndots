# Home configuration for the nixos user on the ISO
# CLI-only — no GUI modules
{ flake, ... }:
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.ssh
    flake.homeModules.nix-index
  ];

  programs.git = {
    settings = {
      user = {
        name = "nixos-iso";
        email = "nixos@iso";
      };
    };
  };
}
