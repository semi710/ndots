# ZMK Firmware

Corne (42-key split) keyboard firmware. The configs, keymap, OLED patches,
layouts and build logic live in [semi710/zmk-config](https://github.com/semi710/zmk-config),
documented at [zmk.semi.sh](https://zmk.semi.sh) - ndots consumes it as a
flake input and gets the packages for free:

```nix
# flake.nix
inputs.zmk-config.url = "github:semi710/zmk-config";

outputs = inputs:
  inputs.nix-wire.mkFlake { inherit inputs; } {
    imports = [ inputs.zmk-config.flakeModules.default ];
  };
```

The flake module adds `packages.zmk` / `packages.zmk-flash` (default keyboard)
and `packages.zmk-<name>` for every keyboard the repo carries. Layouts,
layers and the OLED setup are all on [zmk.semi.sh](https://zmk.semi.sh) -
this page only covers the ndots build/flash angle.

## Build

```bash
just zmk-build    # nix build .#zmk -> result/zmk_{left,right}.uf2
nix run .#zmk-flash    # interactive flash on a Linux host
```

CI in zmk-config builds every keyboard on push; ndots' cache workflow builds
`packages.zmk` on all platforms and pushes it to cachix.

```bash
just zmk    # waits for the latest zmk-config CI run, downloads firmware to zmk/out/
```

## Flash (nice!nano v2)

1. Double-tap the reset button - the half mounts as a USB drive (`NICENANO`)
2. Copy the matching `.uf2` from `result/` (local build) or `zmk/out/` (CI):
    - left half -> `zmk_left.uf2`
    - right half -> `zmk_right.uf2`
3. The half reboots automatically once the file is copied

!!! warning "jp-mbp cannot flash"
    The work MDM on jp-mbp blocks mounting the bootloader volume (Disk
    Arbitration veto), and even raw `mount_msdos` fails - the FAT kext is
    rejected at signature check. Flash from a Linux host instead:

    ```bash
    ssh niksingh710@mach 'rm -f ~/zmk_*.uf2'  # old copies are read-only (nix store perms carried by scp)
    scp result/zmk_*.uf2 niksingh710@mach:~
    # plug the half into mach, double-tap reset, then on mach:
    cp ~/zmk_left.uf2 /run/media/$USER/NICENANO/    # copy = flash
    ```

    The halves must run matching firmware versions to talk to each other -
    flash both back-to-back and expect the keyboard dead in between.

## ZMK Studio

Both halves build with ZMK Studio enabled, so the keymap can be tweaked live
over USB with [ZMK Studio](https://zmk.dev/studio) without reflashing. The
unlock combo is pressing `TAB` + `Q` together.

!!! note
    Studio edits are runtime-only. Lasting changes go in
    `keyboards/corne/corne.keymap` in zmk-config.
