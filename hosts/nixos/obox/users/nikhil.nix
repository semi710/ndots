# Home-manager config for nikhil on obox.
{ flake, ... }:
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.nix-index
  ];
}
