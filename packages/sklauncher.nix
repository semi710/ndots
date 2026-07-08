{
  pkgs,
  lib,
  stdenvNoCC,
  stdenv,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
}:
let
  pname = "sklauncher";
  version = "3.2.18";

  src = pkgs.fetchurl {
    url = "https://skmedix.pl/binaries/skl/${version}/SKlauncher-${version}.jar";
    sha256 = "0qrqs2821vvqz0igpl0mqz1sqfl95q795s2krr5x3n51f0vkx9r5";
  };

  icon = pkgs.fetchurl {
    url = "https://skmedix.pl/images/logo.png";
    sha256 = "sha256-NQpasH/vr1dzeOy1nCo6htD4X6hu2GWUrT8vW2KzLng=";
  };

  commonMeta = {
    description = "SKLauncher - A Minecraft Launcher";
    homepage = "https://skmedix.pl/";
    license = lib.licenses.unfree;
    maintainers = [ ];
    mainProgram = "sklauncher";
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    inherit pname version src;

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.libicns
      pkgs.imagemagick
    ];

    installPhase = ''
      runHook preInstall

      appName="SKLauncher"
      appDir="$out/Applications/$appName.app"

      mkdir -p "$appDir/Contents/MacOS"
      mkdir -p "$appDir/Contents/Resources"

      cp "$src" "$appDir/Contents/Resources/SKlauncher.jar"

      # Convert PNG to ICNS for proper macOS icon
      # First resize to square (512x512) since png2icns requires square images
      magick "${icon}" -resize 512x512! /tmp/icon-square.png
      png2icns "$appDir/Contents/Resources/AppIcon.icns" /tmp/icon-square.png

      cat > "$appDir/Contents/MacOS/sklauncher" <<EOF
      #!/bin/sh
      exec ${lib.getExe pkgs.jdk21} -jar "$appDir/Contents/Resources/SKlauncher.jar" "$@"
      EOF
      chmod +x "$appDir/Contents/MacOS/sklauncher"

      cat > "$appDir/Contents/Info.plist" <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>sklauncher</string>
        <key>CFBundleIdentifier</key>
        <string>pl.skmedix.SKLauncher</string>
        <key>CFBundleName</key>
        <string>SKLauncher</string>
        <key>CFBundleDisplayName</key>
        <string>SKLauncher</string>
        <key>CFBundleVersion</key>
        <string>${version}</string>
        <key>CFBundleShortVersionString</key>
        <string>${version}</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>LSMinimumSystemVersion</key>
        <string>10.14</string>
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
      </plist>
      EOF

      mkdir -p $out/bin
      ln -s "$appDir/Contents/MacOS/sklauncher" "$out/bin/sklauncher"

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

      mkdir -p $out/share/sklauncher
      cp $src $out/share/sklauncher/SKlauncher.jar

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/sklauncher.png

      mkdir -p $out/bin
      makeWrapper ${lib.getExe pkgs.steam-run} $out/bin/sklauncher \
        --add-flags "${lib.getExe pkgs.jdk21} -jar $out/share/sklauncher/SKlauncher.jar"

      runHook postInstall
    '';

    copyDesktopItems = [
      (makeDesktopItem {
        name = "SKLauncher";
        exec = "sklauncher";
        icon = "sklauncher";
        desktopName = "SKLauncher";
        genericName = "Minecraft Launcher";
        categories = [ "Game" ];
      })
    ];

    meta = commonMeta // {
      platforms = [ "x86_64-linux" ];
    };
  }
