{
  pkgs,
  lib,
  ...
}:
{
  home.shellAliases = {
    git-addnospace = "git diff -U0 -w --no-color --src-prefix=a/ --dst-prefix=b/ | git apply --cached --ignore-whitespace --unidiff-zero -";
  };
  home.packages = with pkgs; [
    # Juspay uses merge-based workflow - keep gfm for company repos.
    (writeShellScriptBin "gfm" ''
      if [ -z "$1" ]; then
        echo "Usage: gfm <branch> [remote]"
        exit 1
      fi

      branch="$1"
      remote="''${2:-origin}"

      git fetch "$remote" "$branch" &&
      git merge "$remote/$branch"
    '')
    (writeShellScriptBin "gfr" ''
      if [ -z "$1" ]; then
        echo "Usage: gfr <branch> [remote]"
        exit 1
      fi

      branch="$1"
      remote="''${2:-origin}"

      git fetch "$remote" "$branch" &&
      git rebase "$remote/$branch"
    '')

  ];
  programs = {
    git = {
      enable = true;
      maintenance = {
        enable = true;
        repositories = [
          "$HOME/work/nixpkgs"
        ];
      };
      ignores = [
        "*~"
        "*.swp"
        ".omo"
        ".workmux.yaml"
        ".ua"
        ".understand-anything"
      ];
      lfs.enable = true;
      iniContent = {
        branch.sort = "-committerdate";
      };
      settings = {
        aliases = {
          gl = "log --oneline --graph --decorate";
        };
        init.defaultBranch = "master";
        core.editor = "nvim";
        core.sharedRepository = "group";
        credential.helper =
          if pkgs.stdenv.hostPlatform.isDarwin then "osxkeychain" else "store --file ~/.git-credentials";
        pull.rebase = "true";
        diff.wsErrorHighlight = "none";
        apply.whitespace = "nowarn";
        merge = {
          conflictStyle = "diff3";
          commit = false;
        };
        rerere.enabled = true;
      };
    };
    gh = {
      enable = true;
      extensions = [
        pkgs.gh-notify
      ];
    };
    lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
        # OSC52 clipboard via the proven `copy` tool (works over SSH and in
        # tmux - same path as zsh yanks). The inline printf variant used the
        # DCS-passthrough leg which fails through ssh; copy keys off $TMUX
        # and falls back to plain OSC52 which tmux's set-clipboard forwards.
        os.copyToClipboardCmd = ''printf "%s" {{text}} | ${lib.getExe pkgs.copy}'';
        os.editPreset = "nvim-remote";
        gui = {
          nerdFontsVersion = "3";
          theme.lightTheme = false;
        };
      };
    };
  };
}
