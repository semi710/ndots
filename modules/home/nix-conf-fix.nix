{
  pkgs,
  lib,
  config,
  ...
}:
{
  # attic-client's `attic use` writes `substituters` and `trusted-public-keys`
  # (without the `extra-` prefix) to ~/.config/nix/nix.conf.  On multi-user
  # Nix (daemon), bare `substituters` in user config is silently ignored —
  # only `extra-substituters` appends to the system list.  This activation
  # hook converts the bare keys to their `extra-` equivalents after every
  # home-manager switch so the user-level cache config actually works.
  home.activation.fix-nix-conf-extra-prefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nixConfFile="${config.home.homeDirectory}/.config/nix/nix.conf"

    if [[ -f "$nixConfFile" ]]; then
      if $DRY_RUN_CMD grep -qE '^[[:space:]]*(substituters|trusted-public-keys)[[:space:]]*=' "$nixConfFile"; then
        $VERBOSE_ECHO "Converting ~/.config/nix/nix.conf list settings to extra- prefix..."

        tmpFile="''$nixConfFile.tmp.$$"
        while IFS= read -r line || [[ -n "$line" ]]; do
          if [[ "$line" =~ ^[[:space:]]*substituters[[:space:]]*= ]] && \
             ! [[ "$line" =~ ^[[:space:]]*extra-substituters[[:space:]]*= ]]; then
            $DRY_RUN_CMD echo "$line" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*substituters/extra-substituters/' >> "$tmpFile"
          elif [[ "$line" =~ ^[[:space:]]*trusted-public-keys[[:space:]]*= ]] && \
               ! [[ "$line" =~ ^[[:space:]]*extra-trusted-public-keys[[:space:]]*= ]]; then
            $DRY_RUN_CMD echo "$line" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*trusted-public-keys/extra-trusted-public-keys/' >> "$tmpFile"
          else
            $DRY_RUN_CMD echo "$line" >> "$tmpFile"
          fi
        done < "$nixConfFile"

        $DRY_RUN_CMD mv "$tmpFile" "$nixConfFile"
        $VERBOSE_ECHO "Done: nix.conf list settings now use extra- prefix"
      fi
    fi
  '';
}
