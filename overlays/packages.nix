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

  # fork carries current macOS 27 SA offsets (see flake.nix note); keep the
  # LC_UUID fix - macOS 27 dyld rejects dlopen of images without LC_UUID and
  # nixpkgs' -no_uuid kills the scripting-addition payload inside Dock
  yabai = prev.yabai.overrideAttrs (old: {
    version = "unstable-${inputs.yabai.shortRev}";
    src = inputs.yabai;
    doInstallCheck = false; # fork still reports the last tagged version
    postPatch = builtins.replaceStrings [ "-Wl,-no_uuid" ] [ "" ] old.postPatch;
  });

  # FIXME: remove pin when the flake's nixpkgs pin carries tmux >= 3.8.
  # 3.7x breaks OSC 52 handling (CHANGES 3.7c->3.8: "parsing clipboard
  # sequences", "clipboard or palette replies", "pass which clipboard is set
  # through to the terminal") - dead/wrong clipboard via lazygit c-o, nvim
  # osc52 yank+paste inside tmux. 3.8 also fixes opentui layout corruption
  # on macOS (sst/opencode#34782).
  tmux = prev.tmux.overrideAttrs (old: {
    version = "3.8";
    src = prev.fetchFromGitHub {
      owner = "tmux";
      repo = "tmux";
      rev = "3.8";
      hash = "sha256-pv2wlr3coo+E0pfpb58giJJQn9PGgMFqtVA6nk+9JdE=";
    };
  });

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};
  drag = inputs.dragterm.packages.${final.stdenv.hostPlatform.system}.drag;
  # FIXME: remove pin when the flake's nixpkgs pin carries sesh >= 2.33.0
  # (worktree-aware session naming: git_namer_use_worktree_root/git_dir_length)
  sesh = prev.sesh.overrideAttrs (old: {
    version = "2.33.0";
    src = prev.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "sesh";
      rev = "v2.33.0";
      hash = "sha256-Q25fdn+1T4NOnFX5ZuIMhhRBFSj7dfjybgCj2bu3lK4=";
    };
    vendorHash = "sha256-8CMqOlq3rAXPpzABxd2pp2DhMOvKAN+jHVZ2bLZUN0w=";
  });
  # FIXME: remove when raine/workmux releases the drain-before-close fix
  # (test oversized_unterminated_request_line_is_rejected fails on macOS without it)
  # workmux-sidebar-focus: pane-focus-in dirty signal so the current-AI marker
  # tracks focus moves (no pane-focus hook upstream; marker only refreshed on
  # window/session events, which is why it lagged after sesh session switches)
  workmux = inputs.workmux.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/workmux-drain-inbound.patch
      ./patches/workmux-sidebar-focus.patch
    ];
  });
}
