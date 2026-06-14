{ pkgs, ... }:
{
  home.shellAliases = {
    git-addnospace = "git diff -U0 -w --no-color --src-prefix=a/ --dst-prefix=b/ | git apply --cached --ignore-whitespace --unidiff-zero -";
  };
  home.packages = with pkgs; [
    (writeShellApplication {
      name = "gfm";
      text = ''
        if [ -z "$1" ]; then
          echo "Usage: gfm <branch> [remote]"
          exit 1
        fi

        branch="$1"
        remote="''${2:-origin}"

        git fetch "$remote" "$branch" &&
        git merge "$remote/$branch"
      '';
    })

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
        credential.helper = "store --file ~/.git-credentials";
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
        os.editPreset = "nvim-remote";
        gui = {
          nerdFontsVersion = "3";
          theme.lightTheme = false;
        };
        # OSC52 clipboard integration - works over SSH and in tmux
        # Supports both regular terminals and tmux sessions
        os.copyToClipboardCmd = ''
          if [[ "$TERM" =~ ^(screen|tmux) ]]; then printf "\033Ptmux;\033\033]52;c;$(printf "%s" {{text}} | base64 -w 0)\a\033\\" > /dev/tty; else printf "\033]52;c;$(printf "%s" {{text}} | base64 -w 0)\a" > /dev/tty; fi
        '';
      };
    };
  };
}
