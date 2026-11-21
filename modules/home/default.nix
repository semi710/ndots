{
  flake,
  lib,
  pkgs,
  config,
  ...
}:
let
  me = (import (flake + "/config.nix")).users.me;
in
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

      # xterm-kitty for SSH'd-in sessions from kitty (clear, tmux);
      # the Nix zsh's ncurses looks it up via TERMINFO_DIRS below and
      # via ~/.terminfo, both pointing at the profile's share/terminfo
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

  # Nix zsh links Nix ncurses, which only searches $TERMINFO, ~/.terminfo,
  # $TERMINFO_DIRS and its own store path - never /usr/share/terminfo.
  # targets.genericLinux only exports TERMINFO_DIRS via
  # systemd.user.sessionVariables, which plain SSH logins never import;
  # HM's darwin target has a dedicated terminfo.nix that uses
  # home.sessionVariables instead. Do the same for every Linux home so the
  # session file actually carries it. Pattern mirrors HM's darwin module:
  # profile first, any pre-existing TERMINFO_DIRS in the middle, distro dir last.
  home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    TERMINFO_DIRS = "${config.home.profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}/usr/share/terminfo";
  };

  # Nix ncurses searches ~/.terminfo before TERMINFO_DIRS, so symlink it to
  # the profile's share/terminfo too: works even before hm-session-vars.sh is
  # sourced and follows new generations without baking a store path at build
  # time. On first switch remove any unmanaged ~/.terminfo first (it is only
  # a symlink, safe to delete):  rm ~/.terminfo && home-manager switch
  home.file.".terminfo" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/share/terminfo";
  };

  # SSH into these boxes with the key from config.nix; non-NixOS has no
  # users.users.<n>.openssh.authorizedKeys, so the file is the only way.
  # First switch needs any hand-made ~/.ssh/authorized_keys removed.
  home.file.".ssh/authorized_keys" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    text = lib.concatStringsSep "\n" me.sshPublicKeys + "\n";
  };
}
