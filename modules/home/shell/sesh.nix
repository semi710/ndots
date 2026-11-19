{ pkgs, lib, ... }:
let
  # rows are "active-window + name<TAB>raw session": the active window name
  # carries workmux agent status icons, fzf shows only the display field
  # (--with-nth 1) and connects via the hidden raw session (cut -f2)
  sesh-picker =
    pkgs.writeShellScript "sesh-picker" # bash
      ''
        set +e
        tab=$'\t'
        fmt="{active_window_name_prefix}{name}''${tab}{session}"
        list="sesh list --icons --format \"$fmt\""
        row=$(
          sesh list --icons --format "$fmt" \
            | fzf --tmux 80%,70% \
                --no-sort --ansi \
                --delimiter "$tab" --with-nth 1 \
                --border-label ' sesh ' --prompt '⚡  ' \
                --header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill' \
                --bind 'tab:down,btab:up' \
                --bind "ctrl-a:change-prompt(⚡  )+reload($list)" \
                --bind "ctrl-t:change-prompt(🪟  )+reload($list -t)" \
                --bind "ctrl-g:change-prompt(⚙️  )+reload($list -c)" \
                --bind "ctrl-x:change-prompt(📁  )+reload($list -z)" \
                --bind "ctrl-d:execute-silent(tmux kill-session -t {2})+reload($list)" \
                --preview-window 'right:55%' \
                --preview 'sesh preview {2}'
        )
        [ -n "$row" ] && sesh connect "$(printf '%s' "$row" | cut -f2)"
        exit 0
      '';
in
{
  programs.fzf.tmux.enableShellIntegration = true;
  programs.sesh = {
    enable = true;
    # custom c-o bind below shows workmux agent status icons through the
    # active window name; the hm module's generated bind can't format rows
    enableTmuxIntegration = false;
    settings = {
      # git-derived names: worktree sessions name from their own top-level,
      # so sibling worktrees come out as "bernoulli/dev" (= 1: "dev")
      git_namer_use_worktree_root = true;
      git_dir_length = 2;
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
              nvim --cmd 'let g:auto_session_enabled = v:false' -c 'cd ~/.notes/' -c 'edit index.md'
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
      bind -N "sesh (workmux agent icons on rows) " "c-o" run-shell "${sesh-picker}"
    '';
}
