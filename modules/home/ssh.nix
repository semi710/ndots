{ lib, pkgs, ... }:
{
  # Home-manager ssh config
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = lib.mkMerge [
      {
        forwardAgent = true;
        addKeysToAgent = "yes";
        # For home-manager setups we need to modify /etc/ssh/ssh_config
        # AcceptEnv LANG LC_* JUSPAY_API_KEY ANTHROPIC_* GITHUB_* CLAUDE_*
        sendEnv = [
          "JUSPAY_*"
          "GITHUB_*"
          "ANTHROPIC_*"
          "OPENROUTER_*"
          "OPENCODE_*"
          "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS"
        ];
      }
      (lib.mkIf pkgs.stdenv.isDarwin { useKeychain = true; })
    ];
  };
  # To avoid collision in home-manager
  # see: https://github.com/nix-community/home-manager/issues/4199
  home.file.".ssh/config".force = true;
  services.ssh-agent = lib.mkIf pkgs.stdenv.isLinux { enable = true; };
}
