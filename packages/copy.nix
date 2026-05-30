{
  lib,
  stdenvNoCC,
  coreutils,
  runtimeShell,
}:
stdenvNoCC.mkDerivation {
  pname = "copy";
  version = "0.1.0";

  nativeBuildInputs = [ ];

  unpackPhase = "true";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cat > $out/bin/copy << EOF
    #!${runtimeShell}
    set -euo pipefail
    text=\$(cat)
    encoded=\$(printf '%s' "\$text" | ${coreutils}/bin/base64 | tr -d '\n')
    if [ -n "\''${TMUX:-}" ]; then
      printf '\ePtmux;\e\033]52;c;%s\a\e\\' "\$encoded"
    else
      printf '\033]52;c;%s\007' "\$encoded"
    fi
    EOF
    chmod +x $out/bin/copy
    patchShebangs $out/bin/copy
    runHook postInstall
  '';

  meta = {
    description = "Copy to clipboard via OSC52 (works over SSH and tmux)";
    mainProgram = "copy";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
