{ pkgs, lib, ... }:
{
  programs.fzf.tmux.enableShellIntegration = true;
  programs.sesh = {
    enable = true;
    package = pkgs.sesh.overrideAttrs (oa: rec {
      version = "2.25.0";
      src = pkgs.fetchFromGitHub {
        owner = "joshmedeski";
        repo = "sesh";
        tag = "v${version}";
        hash = "sha256-azs1tf9eR4MVSdjMdd3U/xdPAANn1Kyamf0TwFrBSTU=";
      };
      vendorHash = "sha256-9IiDp/HaxXQAyNzuVBLiO+oIijBbdKBjssCmj8WV9V4=";
    });
    tmuxKey = "c-o";
    settings = {
      blacklist = [
        "^scratch$"
        ".*/Library(/.*)?"
        ".*/Applications(/.*)?"
        ".*/Pictures(/.*)?"
      ];
      dir_length = 2;
      session = [
        rec {
          name = "todo";
          path = "~/.todo/todo.md";
          startup_command = "nvim ${path}";
          preview_command = "${lib.getExe pkgs.glow} ${path}";
        }
        rec {
          name = "notes";
          path = "~/.notes";
          startup_command = # sh
            ''
              nvim --cmd 'let g:auto_session_enabled = v:false' -c 'cd ~/.notes/' -c 'lua vim.schedule(function() vim.cmd("ObsidianQuickSwitch") end)'
            '';
          preview_command = "${lib.getExe pkgs.fzf-preview} ${path}";
        }
        rec {
          name = "LeetCode";
          path = "~";
          startup_command = # sh
            ''
              nvim --cmd 'let g:auto_session_enabled = v:false' -c 'cd ~' -c 'Leet'
            '';
          preview_command = "${lib.getExe pkgs.fzf-preview} ${path}";
        }
        {
          name = "main";
          path = "~";
        }
      ];
    };
  };
  programs.tmux.extraConfig = # tmux
    ''
      bind -N "last-session (via sesh) " "C-p" run-shell "sesh last"
    '';
}
