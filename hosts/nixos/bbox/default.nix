# Beszel hub on Oracle Cloud (bbox).
{ flake, ... }:
{
  imports = [
    (import ../common/cloud.nix { hostName = "bbox"; })
  ]
  ++ flake.inputs.nix-wire.lib.autoImport ./.;
}
