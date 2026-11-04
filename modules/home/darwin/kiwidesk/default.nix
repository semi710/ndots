# KiwiDesk tiling WM - wraps the upstream home-manager module
# (github.com/KiwiCanopy/nix) with the ndots option surface.
{
  flake,
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.kiwidesk;

  # Loaded last: ~/.config/KiwiDesk/local.lua is the mutable,
  # writable layer over this read-only init.lua, so on-the-go
  # tests win. The Lua stdlib is fully open in KiwiDesk (the
  # interpreter runs luaL_openlibs, no sandbox), so io/os/dofile
  # all work.
  localLua = # lua
    ''
      local path = os.getenv("HOME") .. "/.config/KiwiDesk/local.lua"
      local f = io.open(path, "r")
      if f then
        f:close()
        dofile(path)
      end
    '';

  # the CLI ships its own dynamic completion (candidates come
  # from the binary's hidden __complete at runtime); generate the
  # fpath file once at build instead of sourcing per shell
  completion = pkgs.runCommand "kiwidesk-zsh-completion" { } ''
    mkdir -p $out/share/zsh/site-functions
    ${config.programs.kiwidesk.package}/bin/kiwidesk completion zsh \
      > $out/share/zsh/site-functions/_kiwidesk
  '';
in
{
  # upstream module + every module file in this dir; keymap.nix is
  # Lua data (a function, not a module), so it is named, not imported
  imports =
    with builtins;
    [ flake.inputs.kiwicanopy.homeModules.kiwidesk ]
    ++ map (file: ./. + "/${file}") (filter (file: file != "default.nix") (attrNames (readDir ./.)));

  options.kiwidesk = {
    enable = lib.mkEnableOption "KiwiDesk tiling window manager";

    initLua = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra Lua, layered AFTER the default keymap (so it can
        override it) and BEFORE the `local.lua` import. Declaring
        settings makes init.lua the config owner (the Settings
        app then offers "Adopt into the GUI" instead of saving);
        leave empty to keep the Settings app the owner.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kiwidesk = {
      enable = true;
      initLua = lib.concatStringsSep "\n" (
        lib.filter (s: s != "") [
          cfg.initLuaBase
          cfg.initLua
          localLua
        ]
      );
    };

    # before compinit so the CLI's completion lands in fpath
    programs.zsh.initExtraBeforeCompInit = ''
      fpath+=( "${completion}/share/zsh/site-functions" )
    '';
  };
}
