{ inputs, ... }:
final: prev:
let
  inherit (inputs) self;

  # selfPkgs = packages defined in ./packages/*.nix (auto-discovered by
  # nix-wire and exposed as self.packages.${system}).
  selfPkgs = self.packages.${final.stdenv.hostPlatform.system};
in
{
  # From other flake inputs
  stable = import inputs.nixpkgs-stable {
    allowUnfree = true;
    inherit (prev.stdenv.hostPlatform) system;
    overlays = prev.lib.attrValues inputs.self.overlays;
  };
  nsearch-adv = inputs.nsearch.packages.${final.stdenv.hostPlatform.system}.nsearch-adv;

  # From ./packages
  stremio-enhanced = selfPkgs.stremio-enhanced;
  airsync = selfPkgs.airsync;
  hammerspoon = selfPkgs.hammerspoon;
  road-rage = selfPkgs.road-rage;
  skhd-zig = selfPkgs.skhd-zig;
  aria2tui = selfPkgs.aria2tui;
  copy = selfPkgs.copy;
  sklauncher = selfPkgs.sklauncher;

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};

  # Overrides
  # Fix appstream build on Darwin: meson's pthread detection returns
  # "none required" which gets passed to the linker as separate args.
  appstream = prev.appstream.overrideAttrs (oldAttrs: {
    postConfigure =
      (oldAttrs.postConfigure or "")
      + prev.lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
        find . -name "build.ninja" -type f -exec ${prev.perl}/bin/perl -i -pe 's/\s+none\s+required//g' {} \;
      '';
    mesonFlags =
      (oldAttrs.mesonFlags or [ ])
      ++ prev.lib.optional prev.stdenv.hostPlatform.isDarwin "-Dcompose=false";
  });
}
