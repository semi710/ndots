# Beszel hub on Oracle Cloud (obox).
{ flake, ... }:
{
  imports = [
    (import ../common/cloud.nix { hostName = "obox"; })
  ]
  ++ flake.inputs.nix-wire.lib.autoImport ./.;
}
