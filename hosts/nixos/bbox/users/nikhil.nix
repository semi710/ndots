# Home-manager config for nikhil on bbox.
{ flake, ... }:
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.nix-index
  ];
}
