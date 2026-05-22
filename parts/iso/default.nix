{ self, ... }:
{
  # `nix build .#iso`
  iso = self.isoConfigurations.iso.config.system.build.isoImage;
}
