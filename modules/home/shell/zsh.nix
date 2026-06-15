{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.copy ];
  programs.zsh = {
    enable = true;
    completionInit = "autoload -U compinit && compinit -C";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      append = true;
      expireDuplicatesFirst = true;
    };
    sessionVariables = {
      ZVM_SYSTEM_CLIPBOARD_ENABLED = "true";
      ZVM_CLIPBOARD_COPY_CMD = lib.getExe pkgs.copy;
    };
    localVariables = {
      ZVM_VI_INSERT_ESCAPE_BINDKEY = "jk";
    };
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "zsh-fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    initContent = lib.mkOrder 1500 ''
      bindkey '^[j' fzf-tab-complete
      bindkey '^[k' fzf-tab-complete

      # OSC52 Clipboard Integration
      # Uses the `osc` tool which handles tmux escape sequences automatically
      # Note: Visual mode highlight may linger after yanking due to upstream zsh-vi-mode bug
      # https://github.com/jeffreytse/zsh-vi-mode/issues/329
      _osc52_copy() {
        printf '%s' "$1" | ${lib.getExe pkgs.copy}
      }

      _yank_line_with_osc52() {
        zle vi-yank-whole-line
        _osc52_copy "$CUTBUFFER"
      }

      _normal_yank_with_osc52() {
        zle vi-yank
        _osc52_copy "$CUTBUFFER"
      }

      _visual_yank_with_osc52() {
        zle copy-region-as-kill
        _osc52_copy "$CUTBUFFER"
        # Force exit visual mode and clear highlight
        REGION_ACTIVE=0
        if (( $+functions[zvm_exit_visual_mode] )); then
          zvm_exit_visual_mode
        fi
        if (( $+ZVM_REGION_HIGHLIGHT )); then
          ZVM_REGION_HIGHLIGHT=()
        fi
        region_highlight=()
        # Force immediate refresh (clears highlight, moves cursor temporarily)
        zle -U ' '
        zle backward-delete-char
        zle -R
      }

      zle -N _yank_line_with_osc52
      zle -N _normal_yank_with_osc52
      zle -N _visual_yank_with_osc52

      bindkey -M vicmd 'yy' _yank_line_with_osc52
      bindkey -M vicmd 'y' _normal_yank_with_osc52
      bindkey -M visual 'y' _visual_yank_with_osc52

      # Run background + detached (use after Ctrl+Z)
      runbg() { bg %+ >/dev/null 2>&1 && disown %+ >/dev/null 2>&1; }

      function zvm_after_lazy_keybindings() {
        bindkey -M visual 'y' _visual_yank_with_osc52
      }

      [ -f "$HOME/.temp.zsh" ] && source "$HOME/.temp.zsh"
    '';
  };
}

# Discord IPC forwarding for Cord.nvim Rich Presence over SSH
# Uncomment on machines where you use Cord.nvim + Discord:
# ssh() {
#   local HOST="$1"
#   shift
#   local -a SSH_OPTS
#   SSH_OPTS=(
#     -o MACs=hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
#     -o ServerAliveInterval=30
#     -o ServerAliveCountMax=3
#   )
#   local IPC=""
#   if [[ -S "$TMPDIR/discord-ipc-0" ]]; then
#     IPC="$TMPDIR/discord-ipc-0"
#   else
#     local -a sockets
#     sockets=("$TMPDIR"/discord-ipc-*(N))
#     ((${#sockets})) && IPC="${sockets[1]}"
#   fi
#   [[ -z "$IPC" ]] && { command ssh "${SSH_OPTS[@]}" "$HOST" "$@"; return $?; }
#   command ssh -o ConnectTimeout=3 -o BatchMode=yes -o LogLevel=QUIET "${SSH_OPTS[@]}" "$HOST" "rm -f /tmp/discord-ipc-0" 2>/dev/null || true
#   command ssh "${SSH_OPTS[@]}" -o StreamLocalBindUnlink=yes -o ExitOnForwardFailure=yes -R /tmp/discord-ipc-0:"$IPC" "$HOST" "$@"
# }
