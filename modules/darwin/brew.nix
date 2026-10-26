{
  ...
}:
{
  # packages for darwin those are installed via homebrew
  homebrew = {
    casks = [
      "betterdisplay"
      "blip"
      "cleanupbuddy"
      "element"
      "finetune"
      "fliqlo"
      "frankea/whisky/whisky"
      "google-gemini"
      "homerow"
      "hyperkey"
      "imageoptim"
      "impactor"
      "keycastr"
      "localsend"
      "maccy"
      "numi"
      "protonvpn"
      "shottr"
      "sozercan/repo/kaset"
      "steam"
      "utm"
      "whatsapp"
      "windows-app"
      "zulip"
      # "lulu"
    ];
    brews = [
      "tailscale"
    ];
    masApps = {
      # only mac apps supported not iOS one
      "handmirror" = 1502839586;
      "gifski" = 1351639930;
      "gladys" = 1382386877;
      "tailscale" = 1475387142;
      "amphetamine" = 937984704;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      upgrade = true;
      autoUpdate = true;
      cleanup = "zap";
      # Homebrew >= 4.5 requires --force-cleanup for brew bundle install --cleanup --zap
      extraFlags = [
        "--force-cleanup"
      ];
    };
    global.brewfile = true;
    greedyCasks = true;
  };
}
