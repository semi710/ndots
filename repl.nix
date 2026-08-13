{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
in
{
  flake = {
    inherit inputs lib;
    pkgs = lib.genAttrs systems (
      system:
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = lib.attrValues inputs.self.overlays;
      }
    );
  };
}
