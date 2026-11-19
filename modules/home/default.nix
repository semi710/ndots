{
  flake,
  lib,
  pkgs,
  ...
}:
{
  # This has to be same for darwin/home-manager/nixOs.
  home.stateVersion = "26.05";
  fonts.fontconfig.enable = true;

  # I believe no matter the distro/Os,
  # User should have nice cli setup on any device.
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
    flake.homeModules.ssh
    flake.homeModules.nix-index
    flake.homeModules.aria2
    flake.homeModules.nix-conf-fix
    flake.homeModules.naste
  ];
  home.packages =
    with pkgs;
    [
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      carlito
      ipafont
      kochi-substitute
      source-code-pro
      ttf-bitstream-vera
      pkgs.dejavu_fonts

      # xterm-kitty for any box SSH'd into from kitty (clear, tmux);
      # found via TERMINFO_DIRS from targets.genericLinux / HM's darwin target
      kitty.terminfo
    ]
    ++ (with pkgs.nerd-fonts; [
      jetbrains-mono
      fira-code
      droid-sans-mono
    ])
    # lsusb: check a USB device (debug probe, serial adapter) is visible;
    # usbutils is Linux-only
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.usbutils ];
}
