{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  home.sessionVariables = {
    # vim-motions-pi: two-key escape sequence (e.g. jk, jj)
    VIM_MOTION_PI_ESCAPE_SEQUENCE = "jk";
    # vim-motions-pi: custom clipboard command (OSC 52 via copy tool)
    VIM_MOTION_PI_CLIPBOARD_COMMAND = lib.getExe pkgs.copy;
  };

  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.copy # clipboard tool for vim-motions-pi
    ];
    settings = {
      defaultProvider = "anthropic";
      defaultThinkingLevel = "medium";
      theme = "dark";
      packages = [
        "npm:@termdraw/pi"
        "npm:pi-mcp-adapter"
        "npm:vim-motions-pi"
      ];
    };
  };

  # Overwrite npm-installed vim-motions-pi with our fork after pi installs it.
  # Runs after home-manager writes all files, so pi's npm install has already happened.
  home.activation.copyVimMotionsPi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.pi/agent/npm/node_modules/vim-motions-pi"
    if [ -d "$target" ]; then
      $DRY_RUN_CMD chmod -R +w "$target"
      $DRY_RUN_CMD cp -rf ${inputs.vim-motions-pi}/* "$target/"
    fi
  '';
}
