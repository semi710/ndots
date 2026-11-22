{
  config,
  ...
}:
let
  # The live checkout, not ${flake}: that is a read-only store copy and
  # Vorssaint reports its save as failed against it. Link the directory
  # rather than the file - a save replaces the destination, which would
  # clobber a file symlink and drop the repo out of the loop.
  repoDir = "${config.home.homeDirectory}/work/ndots/misc/vorssaint";
in
{
  # settings.plist read at every launch (XDG_CONFIG_HOME aware); in-app
  # saves write through the dir symlink into the repo, so `git diff` shows
  # them and repo edits are live. Managed keys only: omitted preferences
  # stay local in defaults.
  home.file.".config/vorssaint".source = config.lib.file.mkOutOfStoreSymlink repoDir;
}
