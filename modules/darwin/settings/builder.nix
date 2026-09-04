{
  nix.linux-builder = {
    enable = false;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    # sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.linux-builder.plist
    # sudo launchctl bootout system /Library/LaunchDaemons/org.nixos.linux-builder.plist
    # sudo chown $USER /etc/nix/builder_key to ssh
    config =
      { lib, ... }:
      {
        boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        users.users."builder".extraGroups = [ "wheel" ];
        security.sudo.wheelNeedsPassword = false;
        virtualisation = {
          docker.enable = true;
          cores = 6;
          memorySize = lib.mkForce (1024 * 16);
          diskSize = lib.mkForce (1024 * 1024 * 1); # In MB.
        };
      };
  };
}
