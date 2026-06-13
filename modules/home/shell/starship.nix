{ pkgs, lib, ... }:
# `''` escapes ${name} from nix to evaluate
# To get literal `${name}` -> `''${name}`
# Where as in nix `'' This is a string ''`
# '' This is a string ${nixVar} and ''${escaped} ''
let
  gitIcons =
    pkgs.writeShellScriptBin "gitIcons"
      # sh
      ''
        URL=$(command ${lib.getExe pkgs.git} ls-remote --get-url 2> /dev/null)
        declare -A icons=(
          ["github"]=" "
          ["gitlab"]=" "
          ["bitbucket"]=" "
          ["kernel"]=" "
          ["archlinux"]=" "
          ["gnu"]=" "
          ["git"]=" "
        )

        ICON=" "
        URL="''${URL:-localhost}"

        # Prioritize matching longer keys first
        for key in $(printf "%s\n" "''${!icons[@]}" | awk '{ print length, $0 }' | sort -nr | cut -d" " -f2-); do
          if [[ "$URL" == *"$key"* ]]; then
            ICON="''${icons[$key]}"
            break
          fi
        done
        # Clean up the URL
        URL="''${URL#*@}"                      # Remove "git@" if present
        URL="''${URL#*://}"                    # Remove "https://" or "http://"
        URL="''${URL%.git}"                    # Remove ".git" suffix
        URL="''${URL%/}"                       # Remove trailing slash if any

        # Output the final result in "icon: username/repo" format
        printf "%s%s\n" "$ICON" "$URL"
      '';
in
{
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "\${custom.dir}"
        "\${custom.home_dir}"
        "$directory"
        "\${custom.file_number}"
        "\${custom.folder_number}"
        "\${custom.df}"
        "$all"
        "\${custom.git_line_break}"
        "\${custom.git_host}"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_status"
        "\${custom.lastcommit}"
        "$line_break"
        "$character"
      ];
      continuation_prompt = "▶▶ ";
      scan_timeout = 10;
      add_newline = false;
      character = {
        vimcmd_symbol = "";
        success_symbol = "󰘧";
        error_symbol = "";
      };
      directory = {
        format = "[ $path ]($style)[$read_only]($read_only_style)";
        truncation_length = 1;
        read_only = "  ";
        style = "fg: white bg:black bold";
        read_only_style = "fg:red bg:black bold";
        fish_style_pwd_dir_length = 1;
      };
      gcloud = {
        disabled = true;
      };
      custom.home_dir = {
        command = "echo  ";
        shell = [
          "bash"
          "--norc"
          "--noprofile"
        ];
        when = ''
          [ "$PWD" == "$HOME" ]
        '';
        style = "fg:bright-blue bg:black";
        format = "[$output]($style)";
      };
      custom.dir = {
        command = "echo  ";
        shell = [
          "bash"
          "--norc"
          "--noprofile"
        ];
        when = ''
          [ "$PWD" != "$HOME" ]
        '';
        style = "fg:bright-blue bg:black";
        format = "[$output]($style)";
      };
      cmd_duration = {
        show_notifications = false;
        min_time_to_notify = 60000;
      };

      lua.symbol = " ";
      python.format = ''via [ ''${symbol}''${pyenv_prefix}(''${version} )(\($virtualenv\) )]($style)'';
      git_branch = {
        format = ":[$symbol$branch]($style)";
        symbol = " ";
      };
      git_state = {
        format = ''\(:[$state( $progress_current/$progress_total)]($style)\)'';
      };
      git_status = {
        format = "(:[$all_status$ahead_behind]($style)) ";
        conflicted = ''\[ [$count](bright-white bold)\]'';
        ahead = ''\[[ ](bright-blue)[$count](bright-white bold)\]'';
        behind = ''\[[ ](white)[$count](bright-white bold)\]'';
        diverged = ''\[[ ](purple)|[ 󱡷 ](bright-blue)[$ahead_count](bright-white bold)[ 󱡷 ](white)[$behind_count](bright-white)\]'';
        untracked = ''\[ [$count](bright-white bold)\]'';
        stashed = ''\[[󰃖 ](yellow) [$count](bright-white bold)\]'';
        modified = ''\[[ ](bright-yellow)[$count](bright-white bold)\]'';
        staged = ''\[[✓ ](bright-green)[$count](bright-white bold)\]'';
        renamed = ''\[[ ](bright-cyan) [$count](bright-white bold)\]'';
        deleted = ''\[ [$count](bright-white bold)\]'';
      };

      custom.git_line_break = {
        command = "echo";
        when = "${lib.getExe pkgs.git} rev-parse --is-inside-work-tree > /dev/null 2>&1";
        format = "\n";
        shell = [
          "bash"
          "--norc"
          "--noprofile"
        ];
      };
      custom.git_host = {
        command = "${lib.getExe gitIcons}";
        directories = [ ".git" ];
        when = "${lib.getExe pkgs.git} rev-parse --is-inside-work-tree 2> /dev/null";
        style = "bright-yellow bold";
        format = "[$output]($style)";
        shell = [
          "bash"
          "--norc"
          "--noprofile"
        ];
      };
      hostname = {
        ssh_only = true;
        format = "$ssh_symbol$hostname ";
      };

      custom.lastcommit = {
        # Below command will convert `chore(ci): update something` -> `update something`
        # This how it will be ( update something)
        command = "${lib.getExe pkgs.git} show -s --format='|%s' | awk -F'\\|' '{sub(/^.*: /, \"\", $2); msg=substr($2, 1, 30); if (length($2) > 30) msg=msg \"...\"; print \"(\" $1, msg \")\"}'";
        # command = "${lib.getExe pkgs.git} show -s --format=' %h: %s' | awk '{msg=substr($0, index($0,\":\") + 2, 20); if (length($0) - index($0,\":\") > 20) msg=msg \"...\"; print \"(\" $1, msg \")\"}'";
        when = "${lib.getExe pkgs.git} rev-parse --is-inside-work-tree 2> /dev/null";
        style = "#fd9f9f bold";
        format = "\([$output]($style)\) ";
      };

      nix_shell = {
        impure_msg = "[󱋋](bold red)";
        pure_msg = "[](bold green)";
        unknown_msg = "[](bold yellow)";
        format = "[$state( \($name\))](bold blue) ";
        heuristic = true;
      };

      custom.file_number = {
        command = "${lib.getExe pkgs.fd} -t f -H -I -L -d 1 | wc -l";
        when = "exit 0";
        symbol = " ";
        format = "[$symbol$output]($style)";
        style = "fg:white bg:black bold";
      };
      custom.folder_number = {
        command = "${lib.getExe pkgs.fd} -t d -H -I -L -d 1 | wc -l";
        when = "exit 0";
        symbol = "  ";
        format = "[$symbol$output]($style) ";
        style = "fg:white bg:black bold";
      };
    };
  };
}
