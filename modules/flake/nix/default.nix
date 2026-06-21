# Common module for NixOs and darwin
{ inputs, ... }:
{
  imports = inputs.nix-wire.lib.autoImport ./.;
}
