{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    monaspace
  ];
  programs.zsh.enable = true;
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
  system = {
    startup.chime = false;
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    defaults = {
      # aerospace https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
      # for aerospace turn this true and for yabai turn this false
      ".GlobalPreferences"."com.apple.mouse.scaling" = 7.0;
      spaces.spans-displays = false;
      universalaccess.reduceMotion = false;
      trackpad.Clicking = true;
      finder = {
        AppleShowAllExtensions = true;
        CreateDesktop = false;
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowPathbar = true;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXRemoveOldTrashItems = true;
      };
      controlcenter = {
        Bluetooth = false;
        Display = false;
        Sound = false;
        NowPlaying = false;
        BatteryShowPercentage = false;
        FocusModes = false;
        AirDrop = false;
      };
      ActivityMonitor = {
        IconType = 0;
        ShowCategory = 100;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };
      NSGlobalDomain = {
        KeyRepeat = 1;
        AppleMetricUnits = 1;
        InitialKeyRepeat = 20;
        AppleInterfaceStyle = "Dark";
        AppleICUForce24HourTime = true;
        AppleMeasurementUnits = "Centimeters";
        ApplePressAndHoldEnabled = false;
        NSWindowShouldDragOnGesture = true;
        NSAutomaticWindowAnimationsEnabled = false;
        _HIHideMenuBar = true;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.000;
      };
      WindowManager.EnableStandardClickToShowDesktop = false;
      screencapture = {
        show-thumbnail = true;
        target = "clipboard";
      };
      dock = {
        autohide-time-modifier = 0.1;
        static-only = true;
        autohide = true;
        magnification = true;
        largesize = 80;
        mineffect = "genie";
        show-recents = false;
        show-process-indicators = true;
        scroll-to-open = true;
        wvous-br-corner = 1;
        wvous-bl-corner = 1;
        wvous-tr-corner = 1;
        wvous-tl-corner = 1;
        slow-motion-allowed = true;
        expose-animation-duration = 0.0;
        # aerospace https://nikitabobko.github.io/AeroSpace/guide#a-note-on-mission-control
        # Toggle to true for aerospace and false for yabai
        expose-group-apps = false;
        mru-spaces = false;
        persistent-apps = [
          # For custom apps use home-manager location
          # "${config.hm.home.homeDirectory}/Applications/Home Manager Trampolines/kitty.app"
          # "${pkgs.google-chrome}/Applications/Google Chrome.app"
          # "${pkgs.kitty}/Applications/Kitty.app"
          # "/System/Applications/Photos.app"
          # "/System/Applications/FaceTime.app"
          # "/System/Applications/Messages.app"
          # "/System/Applications/Mail.app"
          # "/System/Applications/Calendar.app"
          # "/System/Applications/System Settings.app"
          # "/Applications/Slack.app"
        ];
      };
    };
  };
}
