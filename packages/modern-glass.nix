{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "modern-glass";
  version = "0-unstable-2026-10-22";

  src = fetchFromGitHub {
    owner = "Demetter";
    repo = "ModernGlass";
    rev = "631ba4888b6c1dfa1122db36c90ba3d20c8d3b43";
    hash = "sha256-BXxb/rBZOx332PBljdjAjs7aM3yFkubNz78h6AB+MCI=";
  };

  installPhase = ''
    runHook preInstall
    install -m644 -Dt $out/share/mpv/scripts modernz.lua thumbz.lua
    install -m644 -Dt $out/share/fonts fonts/*.ttf
    runHook postInstall
  '';

  # wrapMpv contract: scriptName is the primary, extras get loaded too;
  # fontDirectories merge the Inter fonts into the wrapper's fontconfig
  passthru = {
    scriptName = "modernz.lua";
    extraScriptsToLoad = [ "thumbz.lua" ];
    fontDirectories = [ "${finalAttrs.finalPackage}/share/fonts" ];
  };

  meta = {
    description = "Glassmorphic OSC for mpv with seekbar thumbnails, forked from ModernZ";
    homepage = "https://github.com/Demetter/ModernGlass";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.all;
  };
})
