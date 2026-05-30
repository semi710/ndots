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

          bind x kill-pane
          bind q kill-window
          bind Q kill-session

          bind V copy-mode
        '';
    };
  };
  home.packages = [
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
