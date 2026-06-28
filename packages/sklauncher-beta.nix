{
  pkgs,
  lib,
  stdenvNoCC,
  stdenv,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  unzip,
}:
let
  pname = "sklauncher-beta";
  version = "4.0.28";

  base = "https://github.com/sklauncher/binaries/releases/download/v${version}";

  # 4.0+ ships native Electron builds (bundled JRE), not the 3.2 JAR.
  src =
    if stdenvNoCC.hostPlatform.isLinux then
      pkgs.fetchurl {
        url = "${base}/SKlauncher-${version}-x86_64.AppImage";
        sha256 = "sha256-0YUa5rK1R8sfztlCno3jv/wA+kAwC9bgKKXkHZx9eJc=";
      }
    else if stdenvNoCC.hostPlatform.isDarwin && stdenvNoCC.hostPlatform.isAarch64 then
      pkgs.fetchurl {
        url = "${base}/SKlauncher-${version}-arm64-mac.zip";
        sha256 = "sha256-DZVus0oLVHE5G2mDUkfonsTPBSg9+GsxJoi1TDzbff0=";
      }
    else
      pkgs.fetchurl {
        url = "${base}/SKlauncher-${version}-mac.zip";
        sha256 = "sha256-j7DRXVUPGr+Te1pdHLSgoe3tEystWwP4PGAA2hlJTZA=";
      };

  icon = pkgs.fetchurl {
    url = "https://skmedix.pl/images/logo.png";
    sha256 = "sha256-NQpasH/vr1dzeOy1nCo6htD4X6hu2GWUrT8vW2KzLng=";
  };

  commonMeta = {
    description = "SKLauncher 4.0 Beta - native Minecraft launcher";
    homepage = "https://next.skmedix.pl/downloads";
    license = lib.licenses.unfree;
    maintainers = [ ];
    mainProgram = "sklauncher-beta";
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [ unzip ];

    unpackPhase = "unzip $src";

    installPhase = ''
      runHook preInstall
      app=$(find . -name "*.app" -type d | head -1)
      mkdir -p "$out/Applications"
      cp -r "$app" "$out/Applications/"
      mkdir -p "$out/bin"
      ln -s "$out/Applications/$(basename "$app")/Contents/MacOS/"* "$out/bin/${pname}"
      runHook postInstall
    '';

    meta = commonMeta // {
      platforms = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  }
else
  stdenv.mkDerivation {
    inherit pname version src;

    dontUnpack = true;

    nativeBuildInputs = [
      makeWrapper
      copyDesktopItems
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/${pname}
      cp $src $out/share/${pname}/SKlauncher.AppImage
      chmod +x $out/share/${pname}/SKlauncher.AppImage

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/${pname}.png

      mkdir -p $out/bin
      makeWrapper ${lib.getExe pkgs.appimage-run} $out/bin/${pname} \
        --add-flags "$out/share/${pname}/SKlauncher.AppImage"
      runHook postInstall
    '';

    copyDesktopItems = [
      (makeDesktopItem {
        name = "SKLauncher Beta";
        exec = pname;
        icon = pname;
        desktopName = "SKLauncher Beta";
        genericName = "Minecraft Launcher";
        categories = [ "Game" ];
      })
    ];

    meta = commonMeta // {
      platforms = [ "x86_64-linux" ];
    };
  }
