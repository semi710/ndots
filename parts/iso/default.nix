{ inputs, self, ... }:
let
  minimalIsoBuilder =
    machine: hostPlatform: opts:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        opts = opts // {
          hostName = machine;
        };
        inherit inputs self hostPlatform;
        flake = inputs.self;
      };
      modules = [ ./minimal.nix ];
    };
in
rec {
  # `nix build .#<name>.config.system.build.isoImage`
  x86ISO = minimalIsoBuilder "nixos" "x86_64-linux" {
    username = "nixos";
    userEmail = "nixos@iso";
  };

  iso = x86ISO.config.system.build.isoImage;
}
