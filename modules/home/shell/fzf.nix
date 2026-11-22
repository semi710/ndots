{ pkgs, lib, ... }:
let
  binds = [
    "--bind='ctrl-d:preview-down'"
    "--bind='ctrl-u:preview-up'"
    "--bind='ctrl-space:toggle'"
    "--bind='ctrl-s:toggle-sort'"
    "--bind='ctrl-y:yank'"
    "--bind='ctrl-alt-p:change-preview-window(down|hidden|)'"
  ];
  defaultOptions = binds ++ [
    "--height 60%"
    "--info inline-right"
    "--layout=reverse"
    "--highlight-line"
    "--multi"
    "--color gutter:-1,selected-bg:238,selected-fg:146,current-fg:189"
  ];
  sortFilesCmd = "${lib.getExe pkgs.eza} -s modified -1 --no-quotes --reverse";
in
{
  home.sessionVariables.FZF_TMUX = lib.mkForce 0;
  programs = {
    sesh.settings = {
      preview_command = "${lib.getExe pkgs.fzf-preview} {}";
    };
    ripgrep.enable = true;
    fzf = {
      enable = true;
      inherit defaultOptions;
      defaultCommand = "fd -t f";
      changeDirWidget = {
        options = binds ++ [ "--preview='${lib.getExe pkgs.eza} -T {}'" ];
        command = "fd -t d";
      };
      fileWidget = {
        options = binds ++ [ "--preview='${lib.getExe pkgs.fzf-preview} {}'" ];
        command = "fd -t f -X ${sortFilesCmd}";
      };
    };
    zsh.initContent = # sh
      ''
        function zvm_after_init() {
          zvm_bindkey viins "^R" fzf-history-widget
          zvm_bindkey viins "^T" fzf-file-widget
        }

        # kitty.conf injects FZF_PREVIEW_IMAGE_HANDLER for local sessions, but
        # ssh drops it (not in sendEnv/AcceptEnv); TERM is the one kitty marker
        # that survives the hop, so derive it for remote hosts. fzf-preview's
        # default handler is sixel, which kitty cannot render - without this,
        # image previews silently vanish over ssh+tmux.
        if [[ -z "''${FZF_PREVIEW_IMAGE_HANDLER:-}" && "$TERM" == xterm-kitty* ]]; then
          export FZF_PREVIEW_IMAGE_HANDLER=kitty
        fi
      '';
    fd = {
      enable = true;
      hidden = true;
      extraOptions = [
        "--no-ignore"
        "--follow"
        "--absolute-path"
      ];
      ignores = [
        ".git/"
        "*.bak"
      ];
    };
  };

  home.packages = [
    pkgs.fzf-preview
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.kitty ];
  # ^ kitty provides `kitten icat` for fzf-preview's kitty image handler;
  # remote sessions run it on the host, the graphics travel through tmux
  # passthrough to the local kitty. darwin gets kitty via programs.kitty.
  home.shellAliases = {
    fzfp = "${lib.getExe pkgs.fzf} --preview='${lib.getExe pkgs.fzf-preview} {}'";
  };
}
