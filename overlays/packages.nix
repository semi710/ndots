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
  modern-glass = selfPkgs.modern-glass;

  # fork carries current macOS 27 SA offsets (see flake.nix note); keep the
  # LC_UUID fix - macOS 27 dyld rejects dlopen of images without LC_UUID and
  # nixpkgs' -no_uuid kills the scripting-addition payload inside Dock
  yabai = prev.yabai.overrideAttrs (old: {
    version = "unstable-${inputs.yabai.shortRev}";
    src = inputs.yabai;
    doInstallCheck = false; # fork still reports the last tagged version
    postPatch = builtins.replaceStrings [ "-Wl,-no_uuid" ] [ "" ] old.postPatch;
  });

  # nixpkgs carries tmux 3.8 now; the override stays only for the
  # XTVERSION fix below - upstream tmux 3.8 still rejects the duplicate
  # reply that allow-passthrough produces
  tmux = prev.tmux.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # with allow-passthrough, pane XTVERSION queries get answered by the outer
      # terminal; the duplicate reply was rejected here and fell through the key
      # parser, typing "kitty(x.y)" into the active pane (ESC P > | k i run as
      # normal-mode keys, the rest lands in the buffer). consume duplicates.
      # drop this if upstream ever consumes repeated extended-DA replies
      sed -i 's/if (tty->flags \& TTY_HAVEXDA)/if (0)/' tty-keys.c
      grep -q 'if (0)' tty-keys.c
    '';
  });

  # From an external pinned flake
  putils = inputs.utils.packages.${prev.stdenv.hostPlatform.system};
  drag = inputs.dragterm.packages.${final.stdenv.hostPlatform.system}.drag;
  # nixpkgs >= 2.34.0 now covers the worktree-aware session naming
  # (git_namer_use_worktree_root/git_dir_length)
  # workmux lives in s-ai now: plugins.workmux installs the binary + skills
  # from the flake input (ndots pins one rev via s-ai.inputs.workmux.follows)
}
