# mirror-leech-telegram-bot - Telegram mirror/leech bot uploading to gdrive via rclone.
# Config and rclone.conf come from sops (secrets/server.yaml, mltb group).
# Runs as root by design: the bot's daemon chain hardcodes /root/.netrc.
{
  config,
  flake,
  lib,
  ...
}:
{
  imports = [ flake.inputs.mltb.nixosModules.mltb ];

  # sabnzbd (daemon dependency) pulls unfree unrar for rar extraction
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "unrarr"
      "unrar"
    ];

  sops.secrets."mltb/config.py" = { };
  sops.secrets."mltb/rclone.conf" = { };

  services.mltb = {
    enable = true;
    configFile = config.sops.secrets."mltb/config.py".path;
    rcloneConfigFile = config.sops.secrets."mltb/rclone.conf".path;
  };
}
