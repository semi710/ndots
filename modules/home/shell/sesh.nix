{ pkgs, lib, ... }:
let
  # sesh ships no completion file and its hm module generates none; the
  # binary emits one. landing in home.packages puts it on the zsh fpath
  # via the profile's share/zsh/site-functions
  completions = pkgs.runCommandLocal "sesh-zsh-completion" { } ''
    ${lib.getExe pkgs.sesh} completion zsh > _sesh
    install -Dm644 _sesh $out/share/zsh/site-functions/_sesh
  '';

  # rows are "name <padding> status-icon<TAB>raw session". window names
  # can't carry workmux status here (automatic-rename overwrites them with
  # the running command), so the icon comes from workmux's own state via
  # `status --json`, joined by tmux session name. fzf shows only the
  # display field (--with-nth 1) and connects via the hidden session
  # (cut -f2). plain_rows renders the same layout without the (slow)
  # workmux lookup so the picker paints immediately; fzf then reloads
  # with icons once the status query returns.
  sesh-picker =
    pkgs.writeShellScript "sesh-picker" # bash
      ''
        set +e
        tab=$'\t'
        self="$0"

        layout() { # layout <icon-map> [extra sesh list flags]
          local list="$1"; shift
          sesh list --icons --format "{name}''${tab}{session}" "$@" \
            | awk -F'\t' -v OFS='\t' '
                NR==FNR { if (NF >= 2) m[$1] = $2; next }
                { name = $1; plain = name; gsub(/\033\[[0-9;]*m/, "", plain)
                  n++; rn[n] = name; rs[n] = $2; rp[n] = plain
                  if (length(plain) > max) max = length(plain) }
                END {
                  for (i = 1; i <= n; i++) {
                    pad = max - length(rp[i]) + 2
                    ic = (rs[i] in m) ? m[rs[i]] : "  "
                    printf "%s%*s%s\t%s\n", rn[i], pad, "", ic, rs[i]
                  }
                }
              ' <(printf '%s\n' "$list") -
        }

        icon_map() {
          workmux status --all --json 2>/dev/null | jq -r '
            def rank: if . == "waiting" then 0 elif . == "working" then 1
                      elif . == "quiet" then 2 elif . == "done" then 3 else 4 end;
            def icon: if . == "waiting" then "💬" elif . == "working" then "🤖"
                      elif . == "quiet" then "○" elif . == "done" then "✅" else "•" end;
            [.agents[]?]
            | group_by(.session)
            | map({ session: .[0].session, icon: (map(.status) | sort_by(rank) | .[0] | icon) })
            | .[] | "\(.session)\t\(.icon)"'
        }

        rows() { # rows [extra sesh list flags] - includes status icons
          layout "$(icon_map)" "$@"
        }

        plain_rows() { # rows [extra sesh list flags] - no status lookup
          layout "" "$@"
        }

        case "$1" in
          --rows) shift; rows "$@"; exit 0 ;;
        esac

        row=$(
          plain_rows \
            | fzf --tmux 80%,70% \
                --no-sort --ansi \
                --delimiter "$tab" --with-nth 1 \
                --border-label ' sesh ' --prompt '⚡  ' \
                --header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill' \
                --bind 'tab:down,btab:up' \
                --bind "start:reload($self --rows)" \
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
  home.packages = [ completions ];
  programs.tmux.extraConfig = # tmux
    ''
      bind -N "last-session (via sesh) " "C-p" run-shell "sesh last"
      bind -N "sesh (workmux agent icons on rows) " "c-o" run-shell "${sesh-picker}"
    '';
}
