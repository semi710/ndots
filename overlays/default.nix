{ inputs, ... }:
final: prev:
let
  allOverlays = [
    (import ./packages.nix { inherit inputs; })
    inputs.llm-agents.overlays.shared-nixpkgs
    # Add more external overlays here as needed:
    # inputs.some-other.overlays.default
  ];
in
prev.lib.composeManyExtensions allOverlays final prev
