{
  description = "Node Vite template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      debug = true;

      # See ./nix/modules/*.nix for the modules that are imported here.
      imports = with builtins; map (fn: ./nix/${fn}) (attrNames (readDir ./nix));
    };
}
