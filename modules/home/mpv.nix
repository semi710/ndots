{ pkgs, ... }:
{
  home.packages = with pkgs; [ ffmpegthumbnailer ];

  # macOS-specific: mpv only loads fonts from ~/.config/mpv/fonts/, not from
  # nix-store paths inside script packages. modernx-zydezu bundles the icon
  # font it needs at share/fonts/truetype/fluent-system-icons.ttf, so we
  # symlink it into mpv's font dir to make the OSC button icons render.
  # (Harmless on Linux; fontconfig already reaches the same file there.)
  xdg.configFile."mpv/fonts/fluent-system-icons.ttf".source =
    "${pkgs.mpvScripts.modernx-zydezu}/share/fonts/truetype/fluent-system-icons.ttf";

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      modernx-zydezu
    ];
    # OSC text font (button icons keep using fluent-system-icons via the
    # font symlink above; this just controls title/time/chapter text).
    scriptOpts.modernx.font = "JetBrainsMono Nerd Font";
    # Stats / keybindings overlay (`?` / `i` / `I`): vim-style minimal look.
    # Scroll with Ctrl+k / Ctrl+j; monospace, thin border, no shadow.
    # Note: stats.lua colors are libass-format BBGGRR — grayscale only here
    # so the channel order is irrelevant.
    scriptOpts.stats = {
      key_scroll_up = "Ctrl+k";
      key_scroll_down = "Ctrl+j";

      font = "JetBrainsMono Nerd Font";
      font_mono = "JetBrainsMono Nerd Font";
      font_size = 18; # large — fills window height on `?` page
      font_color = "E4E4E4"; # soft off-white
      border_size = 3.0; # thick halo, scaled with font, fakes a subtle dark bg
      border_color = "000000"; # pure black halo for max contrast
      shadow_x_offset = 0.0; # flat — no drop shadow
      shadow_y_offset = 0.0;
    };
    bindings = {
      h = "seek -5";
      l = "seek 5";
      j = "cycle sub";
      J = "cycle sub down";
      k = "cycle audio";
      K = "cycle audio down";
      H = "seek -60";
      L = "seek 60";
      "<" = "add window-scale -0.1";
      ">" = "add window-scale 0.1";
      ":" = "script-binding console/enable"; # vim-style ex-cmd opener
    };
    config = {
      osc = "no"; # disable built-in OSC so modernx can render
      save-position-on-quit = "yes";
      ytdl-format = "bestvideo+bestaudio";
      # Let yabai/skhd resize the window freely on macOS. mpv still letterboxes
      # the video correctly via `keepaspect=yes` (default), so this only stops
      # the NSWindow itself from being aspect-locked / size-capped by AppKit.
      keepaspect-window = "no";
    };
  };

  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/x-ms-wmv" = "mpv.desktop";
    "video/x-flv" = "mpv.desktop";
    "video/x-m4v" = "mpv.desktop";
    "video/3gpp" = "mpv.desktop";
    "video/3gpp2" = "mpv.desktop";
    "video/x-matroska-3d" = "mpv.desktop";
    "video/x-ms-asf" = "mpv.desktop";
    "video/x-ms-wvx" = "mpv.desktop";
    "video/x-ms-wmx" = "mpv.desktop";
    "video/x-ms-wm" = "mpv.desktop";
    "video/x-ms-wmp" = "mpv.desktop";
    "video/x-ms-wmz" = "mpv.desktop";
  };
}
