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

  # opencode-vim with corrected npm deps hash and bun version workaround
  # Upstream hashes.json has stale hash(s) for the node_modules fixed-output drv.
  # Upstream's nixpkgs-unstable also regressed to bun 1.3.13, but opencode's
  # build script requires ^1.3.14. We patch the overly-strict version check.
  opencode-vim =
    let
      pkg = inputs.opencode-vim.packages.${final.stdenv.hostPlatform.system}.default;

      # Read upstream hashes.json and patch only the stale platform(s).
      # Corrected hashes discovered from actual build output.
      upstreamHashes = builtins.fromJSON (builtins.readFile "${inputs.opencode-vim}/nix/hashes.json");
      correctedNodeModuleHashes = upstreamHashes.nodeModules // {
        # Override stale hash for x86_64-linux
        x86_64-linux = "sha256-SM30m9rSSuR1dvF/9lBCIMoJoUPkq9wpHcbhECErJfI=";
        # Add other platforms here when tested:
        # aarch64-linux = "sha256-...";
        aarch64-darwin = "sha256-7C6mqePW6m+IgLB/B033sESgh3vyCzrg+VFh6OzcVYo=";
        # x86_64-darwin = "sha256-...";
      };

      node_modules = final.callPackage "${inputs.opencode-vim}/nix/node_modules.nix" {
        hash =
          correctedNodeModuleHashes.${final.stdenv.hostPlatform.system} or (
            throw "opencode-vim: no corrected node_modules hash for ${final.stdenv.hostPlatform.system}. "
            + "Build with 'lib.fakeHash' to discover the correct one."
          );
      };
    in
    (pkg.override { inherit node_modules; }).overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        # Relax bun version check — 1.3.13 works fine for building
        substituteInPlace packages/script/src/index.ts \
          --replace-fail 'throw new Error(`This script requires bun@' '// relaxed: bun version check bypassed - '
      '';
    });

  # Overrides
  # Fix appstream build on Darwin: meson's pthread detection returns
  # "none required" which gets passed to the linker as separate args.
  # Upstream fix: https://github.com/NixOS/nixpkgs/pull/533354 (appstream 1.1.2 -> 1.1.3)
  # Track until merged into our nixpkgs-unstable pin:
  #   nixpkgs-track 533354
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
  #   nixpkgs-track 534779
  telegram-desktop = prev.telegram-desktop.override {
    unwrapped = prev.telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
      nativeBuildInputs =
        (oldAttrs.nativeBuildInputs or [ ])
        ++ prev.lib.optional prev.stdenv.hostPlatform.isDarwin prev.qt6.qtshadertools;
    });
  };
}
