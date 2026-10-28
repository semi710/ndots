{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [ ffmpegthumbnailer ];

  # macOS-specific: mpv only loads fonts from ~/.config/mpv/fonts/, not from
  # nix-store paths inside script packages. ModernGlass bundles the Inter
  # weights it renders its panels with, so symlink them in.
  # (Harmless on Linux; fontconfig already reaches the same files there.)
  xdg.configFile = {
    "mpv/fonts/Inter-Medium.ttf".source = "${pkgs.modern-glass}/share/fonts/Inter-Medium.ttf";
    "mpv/fonts/Inter-SemiBold.ttf".source = "${pkgs.modern-glass}/share/fonts/Inter-SemiBold.ttf";
  };

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.modern-glass ];
    # OSC text font moved into ModernGlass (script-opts/modernz); stats.lua
    # keeps the vim-style look from before.
    scriptOpts.stats = {
      key_scroll_up = "Ctrl+k";
      key_scroll_down = "Ctrl+j";

      font = "JetBrainsMono Nerd Font";
      font_mono = "JetBrainsMono Nerd Font";
      font_size = 18; # large - fills window height on `?` page
      font_color = "E4E4E4"; # soft off-white
      border_size = 3.0; # thick halo, scaled with font, fakes a subtle dark bg
      border_color = "000000"; # pure black halo for max contrast
      shadow_x_offset = 0.0; # flat - no drop shadow
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
      osc = "no"; # disable built-in OSC so ModernGlass can render
      # modernz doesn't disable mpv's core seek bar, which otherwise draws
      # its stock look over the glass panel on every h/l seek
      osd-bar = "no";
      save-position-on-quit = "yes";
      # saved sub-pos fights ModernGlass's sub margins on resume
      watch-later-options-remove = "sub-pos";
      ytdl-format = "bestvideo+bestaudio";
      # Let yabai/skhd resize the window freely on macOS. mpv still letterboxes
      # the video correctly via `keepaspect=yes` (default), so this only stops
      # the NSWindow itself from being aspect-locked / size-capped by AppKit.
      keepaspect-window = "no";

      # precise relative seeks: the default lands h/l skips on keyframes and
      # then re-syncs audio, which reads as janky
      hr-seek = "yes";
      # ModernGlass's glass panels need libplacebo's renderer; works on both
      # darwin and linux builds
      vo = "gpu-next";
      # exact seeks decode from the previous keyframe - hwdec keeps them fast
      # (videotoolbox on darwin, vaapi/nvdec on linux) and saves battery
      hwdec = "auto-safe";
      # mpv's curated quality presets: ewa_lanczossharp scaling, deband, etc.
      profile = "high-quality";
      # clock video to the display, not the audio timeline - smoother cadence
      # for 24fps movies on 60hz screens (audio resamples slightly)
      video-sync = "display-resample";
      # default readahead is 1s; a deeper demuxer buffer lets skips and network
      # streams resume cleanly instead of stuttering up to speed
      demuxer-readahead-secs = "60";
      demuxer-max-bytes = "512MiB";
      demuxer-max-back-bytes = "64MiB";
      # pick up loosely-named .srt files next to the video
      sub-auto = "fuzzy";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # mpv's coreaudio AO fails to init on macOS 27 (channel-map API misuse,
      # mpv#18384; fixes pending in PRs #18637/#18679) so every session falls
      # back to avfoundation anyway - select it directly so coreaudio never
      # runs and its error never logs. drop this when nixpkgs' mpv has the fix
      ao = "avfoundation";
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
