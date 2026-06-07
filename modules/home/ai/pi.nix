{
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
        "git:github.com/semi710/vim-motions-pi@feat/clipboard-and-escape"
      ];
    };
  };

}
