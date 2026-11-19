{ pkgs, ... }:
{

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs.bluez;
    settings.General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };

  # NOTE: telephony_client stays off - the Google Assistant speaker
  # pairing breakage in https://github.com/NixOS/nixpkgs/issues/114222
  # was never re-tested since the hyprland desktop fell out of use
  systemd.user.services.telephony_client.enable = false;
}
