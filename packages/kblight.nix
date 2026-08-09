{
  lib,
  stdenv,
  fetchFromGitHub,
  swift,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kblight";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Maxnflaxl";
    repo = "kblight";
    rev = "8ec63e452e1cf3ed0dd1c3f399aa9261019c2ff2";
    hash = "sha256-C6sTae1OpNMrukc8ZoisUdF4/4O/w/oBpmvYqbcH05o=";
  };

  nativeBuildInputs = [ swift ];

  buildPhase = ''
    runHook preBuild
    swiftc kblight.swift -o kblight
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 kblight $out/bin/kblight
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/Maxnflaxl/kblight";
    description = "Tiny CLI that sets the keyboard backlight on Apple Silicon Macs via the private CoreBrightness framework";
    mainProgram = "kblight";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
})
