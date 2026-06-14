# Shared helper: combine numbered markdown files in ./system-prompts/
# into a single ordered system prompt string.
{ lib }:
let
  dir = ./system-prompts;
  files = lib.filter (f: lib.hasSuffix ".md" f) (builtins.attrNames (builtins.readDir dir));
in
lib.concatMapStringsSep "\n\n" (filename: builtins.readFile "${dir}/${filename}") (
  lib.sort lib.lessThan files
)
