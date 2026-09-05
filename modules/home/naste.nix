# naste CLI client - endpoint only by default.
# Hosts with sops set private.userFile/passFile in their user config.
{
  flake,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.naste-client;

  # same base the naste module defaults to (withPackages: pkgs.extend overlay)
  base = (pkgs.extend flake.inputs.naste.overlays.default).naste;

  privateEnv =
    lib.optional (cfg.private.userFile != null) "--set NASTE_USER_FILE ${cfg.private.userFile}"
    ++ lib.optional (cfg.private.passFile != null) "--set NASTE_PASS_FILE ${cfg.private.passFile}";

  # sessionVariables only reach login shells - bake the env into the
  # binary so every shell (non-login, wrapped tools) gets it too
  wrapped = pkgs.runCommand "naste" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe base} $out/bin/naste \
      --set NASTE_ENDPOINT ${cfg.endpoint} \
      ${lib.concatStringsSep " " privateEnv}
  '';
in
{
  imports = [ flake.inputs.naste.homeModules.default ];

  programs.naste-client = {
    enable = true;
    endpoint = "https://paste.semi.sh";
    # sops hosts get the env-wrapped binary, others keep the normal default
    package = lib.mkIf (cfg.private.userFile != null) wrapped;
  };
}
