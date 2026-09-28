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
        # etm first for modern sshd (OpenSSH 10 defaults dropped non-etm MACs),
        # plain hmac-sha2 kept for legacy servers
        macs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256";
        # For home-manager setups we need to modify /etc/ssh/ssh_config
        # AcceptEnv LANG LC_* JUSPAY_API_KEY ANTHROPIC_* GITHUB_* OPENROUTER_* OPENCODE_*
        sendEnv = [
          "JUSPAY_*"
          "GITHUB_*"
          "ANTHROPIC_*"
          "OPENROUTER_*"
          "OPENCODE_*"
        ];
      }
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { useKeychain = true; })
    ];
  };
  # To avoid collision in home-manager
  # see: https://github.com/nix-community/home-manager/issues/4199
  home.file.".ssh/config".force = true;
  services.ssh-agent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux { enable = true; };
}
