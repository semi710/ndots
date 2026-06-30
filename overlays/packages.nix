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

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};
  drag = inputs.dragterm.packages.${final.stdenv.hostPlatform.system}.drag;

  # opencode-vim: override stale node_modules hash.
  # Upstream's nix-hashes workflow (PRs #192, #196) is configured for ocv but
  # disabled_manually, so hashes.json drifts stale when bun.lock changes.
  # Bun version check is now handled upstream (opencode.nix postPatch).
  # FIX: remove this override once the dev enables the nix-hashes workflow on ocv.
  opencode-vim =
    let
      pkg = inputs.opencode-vim.packages.${final.stdenv.hostPlatform.system}.default;
      upstreamHashes = builtins.fromJSON (builtins.readFile "${inputs.opencode-vim}/nix/hashes.json");
      correctedNodeModuleHashes = upstreamHashes.nodeModules // {
        x86_64-linux = "sha256-Yh6lxJkJPH7c5WYGTW9lI4nfVx2+ZxVmH7ni0CVqbxw=";
        aarch64-darwin = "sha256-7C6mqePW6m+IgLB/B033sESgh3vyCzrg+VFh6OzcVYo=";
      };
      node_modules = final.callPackage "${inputs.opencode-vim}/nix/node_modules.nix" {
        hash =
          correctedNodeModuleHashes.${final.stdenv.hostPlatform.system}
            or (throw "opencode-vim: no corrected node_modules hash for ${final.stdenv.hostPlatform.system}.");
      };
    in
    pkg.override { inherit node_modules; };

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
