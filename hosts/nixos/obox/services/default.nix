# obox service modules — auto-imported via nix-wire.
{ flake, ... }:
{
  imports = flake.inputs.nix-wire.lib.autoImport ./.;
}
