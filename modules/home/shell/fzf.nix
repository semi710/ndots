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

  home.packages = with pkgs; [ fzf-preview ];
  home.shellAliases = {
    fzfp = "${lib.getExe pkgs.fzf} --preview='${lib.getExe pkgs.fzf-preview} {}'";
  };
}
