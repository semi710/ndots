{
  flake,
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nvix.variant = lib.mkOption {
    type = lib.types.enum [
      "bare"
      "core"
      "full"
    ];
    default = "core";
    description = "Choose the variant of nvix to install.";
  };

  config =
    let
      nvix = flake.inputs.nvix.packages.${pkgs.stdenv.hostPlatform.system}.${config.nvix.variant};
    in
    {
      home.sessionVariables.EDITOR = "nvim";
      home.packages = [
        (nvix.extend {
          config = {
            vimAlias = true;
            plugins.codesnap.settings.snapshot_config.watermark = {
              font_family = "CaskaydiaCove Nerd Font";
              # content = lib.mkForce "Code via Nikhil </> niksingh710/semi710";
            };
            extraConfigLua = ''
              if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.TMUX then
                vim.g.clipboard = 'osc52'
              end
            '';
            colorschemes = import ./colorschemes.nix { inherit lib; };
          };
        })
      ];

    };
}
