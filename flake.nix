{
  description = "The Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nix-wire.url = "github:semi710/nix-wire/b8915dd";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # hooks for git
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.flake = false;

    # sops-nix for managing secrets
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # stylix for theming
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # disk management for nixos installations/configurations
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Discord flake
    nixcord.url = "github:kaylorben/nixcord";

    llm-agents.url = "github:numtide/llm-agents.nix";

    opencode-vim.url = "github:leohenon/opencode-vim/ocv";

    # AI tooling sources — vendored at the module level (not full flakes).
    # `flake = false` makes flake.lock track the rev+narHash, so we don't
    # have to hand-manage `sha256` in modules/home/ai/opencode.nix.
    # Bump with: `nix flake update openagents-control claude-code`.
    openagents-control.url = "github:darrenhinde/OpenAgentsControl";
    openagents-control.flake = false;

    claude-code.url = "github:anthropics/claude-code";
    claude-code.flake = false;

    ponytail.url = "github:DietrichGebert/ponytail";
    ponytail.flake = false;

    # nix-index; `,` command available
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # zen till (https://github.com/NixOS/nixpkgs/issues/327982) is resolved.
    # will be resolved once zen comes out of beta.
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Firefox addons/extensions
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minecraft.url = "github:Infinidoge/nix-minecraft";

    # personal flakes
    nvix.url = "github:semi710/nvix";
    utils.url = "github:niksingh710/utils";
    naste.url = "github:semi710/naste";
    dragterm.url = "github:semi710/dragterm";
  };

  outputs =
    inputs:
    inputs.nix-wire.mkFlake {
      inherit inputs;
      imports = [ ./parts ];
    };
}
