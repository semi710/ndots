{ pkgs, lib, ... }:
let
  copyScript = pkgs.writeText "copy-script" ''
    #!/usr/bin/env bash
    text=$(cat)
    if [ -n "''${TMUX:-}" ]; then
      encoded=$(printf '%s' "$text" | ${pkgs.coreutils}/bin/base64 | tr -d '\n')
      printf '\ePtmux;\e\033]52;c;%s\a\e\\' "$encoded"
    else
      encoded=$(printf '%s' "$text" | ${pkgs.coreutils}/bin/base64 | tr -d '\n')
      printf '\033]52;c;%s\007' "$encoded"
    fi
  '';

  copy = pkgs.runCommand "copy" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    cp ${copyScript} $out/bin/copy
    chmod +x $out/bin/copy
    patchShebangs $out/bin/copy
  '';

in
{
  home.packages = [ copy ];
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      append = true;
      expireDuplicatesFirst = true;
    };
    sessionVariables = {
      ZVM_SYSTEM_CLIPBOARD_ENABLED = "true";
      ZVM_CLIPBOARD_COPY_CMD = "${copy}/bin/copy";
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
      # Copies yanked text to system clipboard via OSC52 (works over SSH and tmux)
      # Note: Visual mode highlight may linger after yanking due to upstream zsh-vi-mode bug
      # https://github.com/jeffreytse/zsh-vi-mode/issues/329
      _osc52_copy() {
        local text="$1"
        local encoded=$(printf '%s' "$text" | base64 | tr -d '\n')
        if [[ -n "$TMUX" ]]; then
          printf '\ePtmux;\e\033]52;c;%s\a\e\\' "$encoded"
        else
          printf '\033]52;c;%s\007' "$encoded"
        fi
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
