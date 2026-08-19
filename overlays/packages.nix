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
  kblight = selfPkgs.kblight;

  # FIXME: remove pin when https://github.com/sst/opencode/issues/34782 is fixed
  # 3.7 breaks opentui rendering on macOS only (bold/inline code stripped in TUI)
  tmux =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.tmux.overrideAttrs {
        version = "3.6b";
        src = prev.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = "3.6b";
          hash = "sha256-iW4K/OxSVpxVkyI5Dy6lzwVf/8nXyjcHtL76Ezmxavc=";
        };
      }
    else
      prev.tmux;

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};
  drag = inputs.dragterm.packages.${final.stdenv.hostPlatform.system}.drag;
  opencode-vim = inputs.opencode-vim.packages.${prev.stdenv.hostPlatform.system}.default;
  workmux = inputs.workmux.packages.${prev.stdenv.hostPlatform.system}.default;
}
