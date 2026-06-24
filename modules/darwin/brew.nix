{
  ...
}:
{
  # packages for darwin those are installed via homebrew
  homebrew = {
    taps = [
      "xykong/tap"
      "thusvill/livewallpaper"
    ];
    casks = [
      "betterdisplay"
      "blip"
      "cleanupbuddy"
      "element"
      "homerow"
      "hiddenbar"
      "hyperkey"
      "pronotes"
      "finetune"
      "imageoptim"
      "shottr"
      # "karabiner-elements" # check home/darwin/karabiner.nix
      "keycastr"
      "localsend"
      "flux-markdown"
      # "lulu"
      "livewallpaper"
      "fliqlo"
      "maccy"
      "numi"
      "protonvpn"
      "steam"
      "utm"
      "whatsapp"
      "frankea/whisky/whisky"
      "windows-app"
      "zulip"
    ];
    brews = [
      "cirruslabs/cli/tart"
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
