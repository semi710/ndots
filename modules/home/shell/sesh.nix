{ pkgs, lib, ... }:
let
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
          # sess with a workmux agent: swap sesh's leading source icon for
          # the agent status glyph; others keep their folder/gear icon
          sesh list --icons --format "{name}''${tab}{session}" "$@" \
            | awk -F'\t' '
                NR==FNR { if (NF >= 2 && $2 != "") m[$1] = $2; next }
                ($2 in m) { sub(/^\033\[[0-9;]*m[^\033]+\033\[[0-9;]*m ?/, m[$2] " ") }
                { print }
              ' <(printf '%s\n' "$list") -
        }

        icon_map() {
          workmux status --all --json 2>/dev/null | jq -r '
            def rank: if . == "waiting" then 0 elif . == "working" then 1 else 2 end;
            # nerd-font glyphs: comment (waiting, yellow), spinner
            # (working, blue), check (done, green) - emoji codepoints have
            # no glyph in the configured font and fall back to bullets
            def icon:
              if . == "waiting" then "\u001b[1;33m\uf075\u001b[22;39m"
              elif . == "working" then "\u001b[1;34m\uf110\u001b[22;39m"
              elif . == "done" then "\u001b[1;32m\uf00c\u001b[22;39m" else "" end;
            [.agents[]?]
            | group_by(.session)
            | map({ session: .[0].session, icon: (map(.status) | sort_by(rank) | .[0] | icon) })
            | map(select(.icon != ""))
            | .[] | "\(.session)\t\(.icon)"'
        }

        rows() { # rows [extra sesh list flags] - includes status icons
          layout "$(icon_map)" "$@"
        }

        plain_rows() { # rows [extra sesh list flags] - no status lookup
          layout "" "$@"
        }

        band() { # band <text> - bg-tinted line separating the header from the preview
          local t="$1" plain pad
          plain=$(printf '%s' "$t" | sed $'s/\x1b\\[[0-9;]*m//g')
          pad=$((68 - ''${#plain}))
          [ "$pad" -lt 0 ] && pad=0
          printf "\033[48;2;40;39;39m\033[38;2;220;215;186m %s%*s \033[0m\n" "$t" "$pad" ""
        }

        case "$1" in
          --rows) shift; rows "$@"; exit 0 ;;
          --preview)
            s="$2"
            pidx=$(tmux list-panes -a -F '#{pane_id} #{window_index}' 2>/dev/null \
              | jq -R -s 'split("\n") | map(select(length > 0) | split(" ") | {(.[0]): (.[1] | tonumber)}) | add // {}')
            # one line: total agents, then per-window count+icon groups in
            # window order; agents without a real status are ignored
            hdr=$(workmux status --all --json 2>/dev/null | jq -r --arg s "$s" --argjson pidx "$pidx" '
              def icon($st):
                if $st == "waiting" then "\u001b[1;33m\uf075\u001b[22;39m"
                elif $st == "working" then "\u001b[1;34m\uf110\u001b[22;39m"
                else "\u001b[1;32m\uf00c\u001b[22;39m" end;
              [.agents[]? | select(.session == $s) | .wind = ($pidx[.pane_id] // 999999)] as $a
              | [$a[] | select(.status == "waiting" or .status == "working" or .status == "done")] as $r
              | if ($r | length) == 0 then empty
                else
                  ($r | length) as $total
                  | $a
                  | group_by(.wind)
                  | sort_by(.[0].wind)
                  | map(. as $g
                        | (["waiting", "working", "done"]
                           | map(. as $st
                                 | ($g | map(select(.status == $st)) | length) as $n
                                 | select($n > 0)
                                 | "\($n) \(icon($st))")
                           | join(" ")))
                  | map(select(length > 0))
                  | " \($total): \(join(" | "))"
                end')
            if [ -n "$hdr" ]; then band "$hdr"; printf "\n"; fi
            sesh preview "$s"
            exit 0
            ;;
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
                --preview-label ' agents ' \
                --preview "$self --preview {2}"
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
