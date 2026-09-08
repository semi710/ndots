{ pkgs, lib, ... }:
let
  edit-pane =
    pkgs.writeShellScript "edit-pane" # sh
      ''
        buf=$(mktemp).sh
        # -32768 is the length of the buffer
        # Why -32768? Coz everyone using this
        tmux capture-pane -pS -32768 > "$buf"
        tmux new-window -n:edit-pane "$EDITOR $buf"
      '';

  workmux-sidebar =
    pkgs.writeShellScript "workmux-sidebar" # sh
      ''
        set +e
        sidebar=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep ' workmux$' | awk '{print $1}' | head -1)
        active=$(tmux display -p '#{pane_id}' 2>/dev/null)
        if [ -z "$sidebar" ]; then
          # Not open → open and focus
          workmux sidebar --session 2>/dev/null
          for i in 1 2 3 4 5 6 7 8 9 10; do
            sidebar=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep ' workmux$' | awk '{print $1}' | head -1)
            [ -n "$sidebar" ] && break
            sleep 0.1
          done
          [ -n "$sidebar" ] && tmux select-pane -t "$sidebar" 2>/dev/null
        elif [ "$sidebar" = "$active" ]; then
          # Focused → close
          tmux kill-pane -t "$sidebar" 2>/dev/null
        else
          # Open but not focused → focus
          tmux select-pane -t "$sidebar" 2>/dev/null
        fi
        exit 0
      '';

  workmux-dashboard =
    pkgs.writeShellScript "workmux-dashboard" # sh
      ''
        tab="''${1:-}"
        h=$(tmux display -p '#{window_height}')
        w=$(tmux display -p '#{window_width}')
        h=$((h * 9 / 10))
        w=$((w * 9 / 10))
        if [ -n "$tab" ]; then
          tmux display-popup -h "$h" -w "$w" -E "workmux dashboard --tab $tab"
        else
          tmux display-popup -h "$h" -w "$w" -E "workmux dashboard"
        fi
      '';

  equalize-layout =
    pkgs.writeShellScript "equalize-layout" # sh
      ''
        # select-layout is window-wide, so size panes directly instead: the
        # workmux sidebar keeps its size and hosts without workmux still work
        panes=$(tmux list-panes -F '#{pane_id} #{pane_left} #{pane_top} #{pane_width} #{pane_height} #{pane_current_command}')
        main=$(printf '%s\n' "$panes" | awk '$6 != "workmux"')
        n=$(printf '%s\n' "$main" | grep -c .)
        [ "$n" -lt 2 ] && exit 0

        # same left edge means stacked, same top edge means side by side
        if [ "$(printf '%s\n' "$main" | awk '{print $2}' | sort -u | wc -l)" -eq 1 ]; then
          axis=y
          size_field=5
          pos_field=3
        elif [ "$(printf '%s\n' "$main" | awk '{print $3}' | sort -u | wc -l)" -eq 1 ]; then
          axis=x
          size_field=4
          pos_field=2
        else
          tmux display-message "equalize skipped: mixed layout"
          exit 0
        fi

        total=$(printf '%s\n' "$main" | awk -v f="$size_field" '{s += $f} END {print s}')
        share=$((total / n))

        # the geometrically last pane is left alone and absorbs the remainder
        printf '%s\n' "$main" | sort -k"$pos_field,$pos_field"n | head -n -1 |
          while read -r id _; do
            tmux resize-pane -t "$id" "-$axis" "$share"
          done

        tmux display-message "equalized $n panes"
      '';
in
{
  programs = {
    tmux = {
      enable = true;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      shortcut = "a";
      escapeTime = 0;
      historyLimit = 1000000;
      secureSocket = false;
      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = minimal-tmux-status;
          extraConfig = ''
            set -g @minimal-tmux-bg "#282727"
            set -g @minimal-tmux-fg "#c8c093"
            set -g @minimal-tmux-use-arrow true
            set -g @minimal-tmux-right-arrow ""
            set -g @minimal-tmux-left-arrow ""
          '';
        }
        better-mouse-mode
        {
          plugin = fzf-tmux-url;
          extraConfig = ''
            set -g @fzf-url-bind 'u'
            set -g @fzf-url-copy-cmd '${lib.getExe pkgs.copy}'
          '';
        }
        {
          plugin = vim-tmux-navigator;
          extraConfig = ''
            # vim-tmux-navigator: Only treat actual vim instances as vim
            # Exclude lazygit and other TUIs by using a strict pattern
            # Matches: vim, nvim, view, fzf (but NOT lazygit)
            set -g @vim_navigator_pattern '(\S+/)?\.?(g?(view|n?vim?x?)(diff)?|fzf)(-wrapped)?$'
          '';
        }
      ];
      extraConfig = # tmux
        ''
          set -g allow-passthrough all
          set -g extended-keys on
          set -g extended-keys-format csi-u
          set -g default-command "''${SHELL}"

          set -g default-terminal "tmux-256color"
          set -as terminal-overrides ",*:Tc"
          set-option -g status-position top

          # Undercurl
          set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
          set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

          # Check if we are in WSL
          if-shell 'test -n "$WSL_DISTRO_NAME"' {
            set -as terminal-overrides ',*:Setulc=\E[58::2::::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m' # underscore colours - needs tmux-3.0 (wsl2 in Windows Terminal)
          }

          set-environment -g COLORTERM "truecolor"

          set-option -ga update-environment "UPTERM_ADMIN_SOCKET"
          set-option -ga update-environment "SSH_AUTH_SOCK"

          set -g set-clipboard on
          set-option -g automatic-rename on
          set-option -g status-style bg=default
          set -g prefix C-a

          bind N new-session
          bind n new-window

          bind H swap-pane -D
          bind L swap-pane -U

          bind -r < swap-window -t -1 \; select-window -t -1
          bind -r > swap-window -t +1 \; select-window -t +1

          # edit tmux output in vim `ctrl e`
          bind C-e run-shell "${edit-pane}"

          bind-key r movew -r\; display-message "Renumbered Windows"

          bind-key C send-keys -R \; clear-history

          # window remap `-r` allows to repeat the keyb
          bind -r C-h previous-window
          bind -r C-l next-window

          bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
          set -g detach-on-destroy off  # don't exit from tmux when closing a session

          # start selecting text with "v"
          bind -T copy-mode-vi 'v' send -X begin-selection
          bind -T copy-mode-vi 'C-v' send -X rectangle-toggle

          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel
          bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

          bind b set-option  status

          bind v split-window -h -c "#{pane_current_path}"
          bind s split-window -v -c "#{pane_current_path}"

          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"

          bind S choose-session

          bind -r j resize-pane -D
          bind -r k resize-pane -U
          bind -r l resize-pane -R
          bind -r h resize-pane -L
          bind -r m resize-pane -Z

          # equalize splits; the workmux sidebar (if any) keeps its size
          bind e run-shell "${equalize-layout}"

          bind x kill-pane
          bind q kill-window
          bind Q kill-session

          bind V copy-mode

          # workmux: toggle agent sidebar, focus on open
          bind C-a run-shell "${workmux-sidebar}"
          # workmux: full dashboard popup (90% of window)
          # TODO: add --preview-side right when https://github.com/raine/workmux/issues/241 lands
          bind C-s run-shell "${workmux-dashboard}"
          # workmux: dashboard on worktrees tab (90% of window)
          bind C-w run-shell "${workmux-dashboard} worktrees"
        '';
    };
  };
  home.packages = [
    pkgs.workmux
    (pkgs.writeShellScriptBin "ta" ''
      session="$1"

      if [ -z "$session" ]; then
        echo "Usage: ta <session-name>"
        exit 1
      fi

      if [ -z "$TMUX" ]; then
        tmux -u new-session -A -s "$session"
      else
        if tmux has-session -t "$session" 2>/dev/null; then
          tmux switch-client -t "$session"
        else
          tmux new-session -d -s "$session"
          tmux switch-client -t "$session"
        fi
      fi
    '')
  ];
}
