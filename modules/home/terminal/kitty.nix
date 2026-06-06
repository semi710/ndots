{ lib, flake, ... }:
with lib;
let
  fontFeatureString =
    name: # conf
    ''
      clipboard_control write-primary write-clipboard no-append
      font_features Monaspace${name}Var-Bold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-BoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-ExtraBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-ExtraBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-ExtraLightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-Italic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-Light +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-LightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-Medium +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-MediumItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideExtraBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideExtraBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideExtraLight +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideExtraLightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideLight +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideLightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideMedium +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideMediumItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideRegular +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideSemiBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-SemiWideSemiBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideExtraBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideExtraBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideExtraLight +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideExtraLightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideLight +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideLightItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideMedium +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideMediumItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideRegular +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideSemiBold +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
      font_features Monaspace${name}Var-WideSemiBoldItalic +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08
    '';
in
{
  home.file."tab-bar" = {
    source = "${flake}/misc/tab_bar.py";
    target = ".config/kitty/tab_bar.py";
  };
  programs = {
    kitty = {
      enable = mkDefault true;
      environment.FZF_PREVIEW_IMAGE_HANDLER = "kitty";
      keybindings = {
        "cmd+opt+s" = "no_op";
        "cmd+l" = "next_tab";
        "cmd+h" = "previous_tab";
        "cmd+u" = "open_url_with_hints";
        "cmd+q" = "close_tab";
      };
      extraConfig = # conf
        ''
          # Enable ligatures in `monaspace font`
          # picked from: <https://github.com/kovidgoyal/kitty/issues/7251#issuecomment-2016430720>
          ${fontFeatureString "Radon"}
          ${fontFeatureString "Krypton"}
          ${fontFeatureString "Argon"}
          ${fontFeatureString "Neon"}
          map shift+enter send_text all \x1b[13;2u
        '';
      settings = {
        background_opacity = lib.mkForce "0.85";
        background_blur = 32;
        window_padding_width = 0;
        hide_window_decorations = "titlebar-only";
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        macos_option_as_alt = "yes";
        dynamic_background_opacity = "yes";
        scrollback_lines = 1000000;

        # tabs
        # I rely on tmux, but still for those who want tabs
        tab_bar_style = "custom";
        tab_separator = ''""'';
        tab_fade = "0 0 0 0";
        tab_title_template = "{title}";
        active_tab_title_template = "{title}";
        tab_bar_margin_width = 0.0;
        tab_bar_edge = "bottom";
        tab_bar_align = "left";
        tab_bar_margin_height = 0.0;
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        tab_bar_min_tabs = 2;
        tab_activity_symbol = "none";
        cursor_trail = 3;

        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
      };
    };
  };
}
