{
  imports =
    with builtins;
    map (file: ./${file}) (filter (file: (file != "default.nix")) (attrNames (readDir ./.)));
}
