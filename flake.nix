{
  description = "The Configuration";

  nixConfig = {
    extra-substituters = [
      "https://nvix.cachix.org"
      "https://nija.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nvix.cachix.org-1:qVYAfj2oiH0DF3pSs8OfPYI6B0mAZ+h5mMajN+EOL2E="
      "nija.cachix.org-1:wJRNRxBn1M1SAgzVv5ZAMe07ky6bkSSznMH0tEOFdcA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nix-wire.url = "github:semi710/nix-wire";
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

    # AI agents (opencode, omp, pi) with shared skills/prompts/mcp/providers.
    # Bump with: `nix flake update s-ai`.
    s-ai.url = "github:semi710/s-ai";

    # Understand Anything - codebase-to-knowledge-graph skills (/understand*).
    # Skills are markdown + scripts; the dashboard ships as a prebuilt npx
    # tarball, so the read-only store checkout works as plugin root.
    # Bump with: `nix flake update understand-anything`.
    understand-anything.url = "github:Egonex-AI/Understand-Anything";
    understand-anything.flake = false;

    # yabai with macOS 27 (Golden Gate) scripting-addition support:
    # AhsanFazal/yabai resolves SA offsets for every 27.x build so far
    # (27.0-27.2, both arm64e slices); space focus is SA-based and instant
    # (agg23's synthetic dock-swipes animate). 27.2 loses space --move
    # (Dock rewrite) - stay on 27.0.1 until that's needed.
    # Bump with: `nix flake update yabai`.
    yabai.url = "github:AhsanFazal/yabai";
    yabai.flake = false;

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
    utils.url = "github:semi710/utils";
    naste.url = "github:semi710/naste";
    dragterm.url = "github:semi710/dragterm";
    mltb.url = "github:semi710/mirror-leech-telegram-bot";
    mltb.inputs.nixpkgs.follows = "nixpkgs";

    workmux.url = "github:raine/workmux";

    # zmk keyboard firmware - configs live in semi710/zmk-config
    zmk-config.url = "github:semi710/zmk-config";
  };

  outputs =
    inputs:
    inputs.nix-wire.mkFlake {
      inherit inputs;
      imports = [
        inputs.zmk-config.flakeModules.default
        ./parts
        ./repl.nix
      ];
    };
}
