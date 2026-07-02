{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "bitbucket-server-mcp";
  version = "unstable-2026-06-30";

  src = fetchFromGitHub {
    owner = "garc33";
    repo = "bitbucket-server-mcp-server";
    rev = "f57cb86247865b67979d2fac55ef9a7b17f90ca6";
    hash = "sha256-NMsYI7QWA0AZQ+P/nt8h+L6ybbOgVUaMYOuVjvhETDo=";
  };

  npmDepsHash = "sha256-RzUHT2WqNIviibZ7nHIFOCziCYeRW9XoO1N2Y9njQ2U=";

  # postinstall chmod's the binary; build runs tsc
  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/bitbucket-server-mcp $out/bin
    cp -r build node_modules package.json $out/lib/bitbucket-server-mcp/
    ln -s $out/lib/bitbucket-server-mcp/build/index.js $out/bin/bitbucket-server-mcp
    runHook postInstall
  '';

  meta = {
    description = "MCP server for Bitbucket Server/Data Center PR management";
    homepage = "https://github.com/garc33/bitbucket-server-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "bitbucket-server-mcp";
    platforms = lib.platforms.unix;
  };
}
