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
      # "hyperkey" # vorssaint has hyperkey
      "imageoptim"
      "impactor"
      "keycastr"
      "localsend"
      "maccy" # vorssaint has clipboard (but maccy is best)
      "numi"
      "protonvpn"
      # "shottr"
      "sozercan/repo/kaset"
      "steam"
      "utm"
      "vorssaint"
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
      # "handmirror" = 1502839586; # vorssaint has camera preview
      "gifski" = 1351639930;
      # "gladys" = 1382386877; # vorssaint has drag drop
      # "amphetamine" = 937984704; # vorssaint has always on
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      # never upgrade on activation: casks upgrade themselves in-app, and one
      # failing CDN (whatsapp's has reset connections) fails the whole deploy
      upgrade = false;
      autoUpdate = true;
      cleanup = "zap";
      # Homebrew >= 4.5 requires --force-cleanup for brew bundle install --cleanup --zap
      extraFlags = [
        "--force-cleanup"
      ];
    };
    global.brewfile = true;
    # no greedyCasks: auto-update casks (whatsapp etc.) upgrade in-app; brew
    # chasing them on every activation just gambles the deploy on their CDN
  };
}
