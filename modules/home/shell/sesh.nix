{ pkgs, lib, ... }:
let
  # rows are "status-icon name<TAB>raw session". window names can't carry
  # workmux status here (automatic-rename overwrites them with the running
  # command), so the icon comes from workmux's own state via `status --json`,
  # joined by tmux session name. fzf shows only the display field
  # (--with-nth 1) and connects via the hidden raw session (cut -f2).
  sesh-picker =
    pkgs.writeShellScript "sesh-picker" # bash
      ''
        set +e
        tab=$'\t'
        self="$0"

        rows() { # rows [extra sesh list flags]
          local list
          list=$(workmux status --all --json 2>/dev/null | jq -r '
            def rank: if . == "waiting" then 0 elif . == "working" then 1
                      elif . == "quiet" then 2 elif . == "done" then 3 else 4 end;
            def icon: if . == "waiting" then "💬" elif . == "working" then "🤖"
                      elif . == "quiet" then "○" elif . == "done" then "✅" else "•" end;
            [.agents[]?]
            | group_by(.session)
            | map({ session: .[0].session, icon: (map(.status) | sort_by(rank) | .[0] | icon) })
            | .[] | "\(.session)\t\(.icon)"')
          sesh list --icons --format "{name}''${tab}{session}" "$@" \
            | awk -F'\t' -v OFS='\t' '
                NR==FNR { if (NF >= 2) m[$1] = $2; next }
                { disp = $1; if ($2 in m) disp = m[$2] " " disp; print disp "\t" $2 }
              ' <(printf '%s\n' "$list") -
        }

        case "$1" in
          --rows) shift; rows "$@"; exit 0 ;;
        esac

        row=$(
          rows \
            | fzf --tmux 80%,70% \
                --no-sort --ansi \
                --delimiter "$tab" --with-nth 1 \
                --border-label ' sesh ' --prompt '⚡  ' \
                --header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill' \
                --bind 'tab:down,btab:up' \
                --bind "ctrl-a:change-prompt(⚡  )+reload($self --rows)" \
                --bind "ctrl-t:change-prompt(🪟  )+reload($self --rows -t)" \
                --bind "ctrl-g:change-prompt(⚙️  )+reload($self --rows -c)" \
                --bind "ctrl-x:change-prompt(📁  )+reload($self --rows -z)" \
                --bind "ctrl-d:execute-silent(tmux kill-session -t {2})+reload($self --rows)" \
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
    # custom c-o bind below shows workmux agent status icons (joined from
    # `workmux status --json`, so window names/automatic-rename don't
    # matter); the hm module's generated bind can't format rows
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
