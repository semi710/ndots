{ flake, pkgs, ... }:
let
  nixvim = flake.inputs.nvix.inputs.nixvim;
  nixvimOptions =
    nixvim.packages.${pkgs.stdenv.hostPlatform.system}.options-json + "/share/doc/nixos/options.json";

  opener = if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open";

  mkIndexChannel = index: {
    metadata = {
      name = index;
      description = "Search ${index} packages and options";
    };
    source.command = "nix-search-tv print --indexes ${index}";
    preview.command = ''nix-search-tv preview --indexes ${index} "{}"'';
    keybindings = {
      ctrl-r = "actions:run";
      ctrl-i = "actions:shell";
      ctrl-s = "actions:source";
      ctrl-o = "actions:homepage";
    };
    actions.run = {
      description = "Run the package";
      command = ''nix run {replace:s/\/ /#/g}'';
      mode = "execute";
    };
    actions.shell = {
      description = "Enter new nix shell with this package";
      command = ''nix shell {replace:s/\/ /#/g}'';
      mode = "execute";
    };
    actions.source = {
      description = "Open link to source code";
      command = ''nix-search-tv source --indexes ${index} "{}" | xargs ${opener}'';
      mode = "execute";
    };
    actions.homepage = {
      description = "Open link to homepage";
      command = ''nix-search-tv homepage --indexes ${index} "{}" | xargs ${opener}'';
      mode = "execute";
    };
  };

  indexes = [
    "nixpkgs"
    "home-manager"
    "nixos"
    "darwin"
    "nur"
    "noogle"
    "nixvim"
  ];
in
{
  programs = {
    television = {
      enable = true;
      enableZshIntegration = false;
      settings.keybindings = {
        esc = "quit";
        ctrl-c = "quit";

        ctrl-n = "select_next_entry";
        ctrl-p = "select_prev_entry";
        down = "select_next_entry";
        up = "select_prev_entry";

        ctrl-d = "scroll_preview_half_page_down";
        ctrl-u = "scroll_preview_half_page_up";
        pagedown = "scroll_preview_half_page_down";
        pageup = "scroll_preview_half_page_up";

        enter = "confirm_selection";
        tab = "toggle_selection_down";
        backtab = "toggle_selection_up";

        ctrl-y = "copy_entry_to_clipboard";
        ctrl-r = "reload_source";
        ctrl-s = "cycle_sources";
        ctrl-f = "cycle_previews";

        ctrl-t = "toggle_remote_control";
        ctrl-x = "toggle_action_picker";
        ctrl-o = "toggle_preview";
        ctrl-g = "toggle_help";
        f12 = "toggle_status_bar";
        ctrl-l = "toggle_layout";

        backspace = "delete_prev_char";
        ctrl-w = "delete_prev_word";
        delete = "delete_next_char";
        left = "go_to_prev_char";
        right = "go_to_next_char";
        home = "go_to_input_start";
        end = "go_to_input_end";
        ctrl-e = "go_to_input_end";

        ctrl-up = "select_prev_history";
        ctrl-down = "select_next_history";
      };

      channels = builtins.listToAttrs (
        map (index: {
          name = index;
          value = mkIndexChannel index;
        }) indexes
      );
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
      settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
          "nixos"
          "darwin"
          "nur"
          "noogle"
        ];
        experimental.options_file.nixvim = "${nixvimOptions}";
      };
    };
  };

  home.shellAliases.ns = "tv nix-search-tv";
}
