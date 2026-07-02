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
  sklauncher-beta = selfPkgs.sklauncher-beta;
  bitbucket-mcp = selfPkgs.bitbucket-mcp;

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};
  drag = inputs.dragterm.packages.${final.stdenv.hostPlatform.system}.drag;
  opencode-vim = inputs.opencode-vim.packages.${final.stdenv.hostPlatform.system}.default;

  # Overrides
  # Fix appstream build on Darwin: meson's pthread detection returns
  # "none required" which gets passed to the linker as separate args.
  # Upstream fix: https://github.com/NixOS/nixpkgs/pull/533354 (appstream 1.1.2 -> 1.1.3)
  # Track until merged into our nixpkgs-unstable pin:
  #   FIX: nixpkgs-track 533354
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

  # Fix telegram-desktop build on Darwin: QSB (Qt Shader Baker) not found.
  # qtshadertools provides the qsb binary needed to compile Telegram shaders.
  # Upstream fix: https://github.com/NixOS/nixpkgs/pull/534779
  # Track until merged into our nixpkgs-unstable pin:
  #   FIX: nixpkgs-track 534779
  telegram-desktop = prev.telegram-desktop.override {
    unwrapped = prev.telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
      nativeBuildInputs =
        (oldAttrs.nativeBuildInputs or [ ])
        ++ prev.lib.optional prev.stdenv.hostPlatform.isDarwin prev.qt6.qtshadertools;
    });
  };
}
