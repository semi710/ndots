# Minecraft

Paper server on **obox**, via the `nix-minecraft` flake input. Declared in `modules/nixos/minecraft/` and imported by `hosts/nixos/obox/minecraft.nix`.

## Configuration

- Paper 26.2 (`pkgs.paperServers.paper-26_2`), port `25565` TCP, `openFirewall = true`
- Simple Voice Chat on UDP `24454` (`networking.firewall.allowedUDPPorts`)
- `online-mode = false` (offline mode, matches by name), `white-list = true`
- Whitelist lives in `modules/nixos/minecraft/users.nix`
- State (world, logs, rendered `server.properties`) under `/srv/minecraft/obox`

## Connect

Multiplayer -> Add Server -> `<obox-ip>:25565`. Port is the default, so the bare IP works. Voice chat additionally needs UDP `24454` reachable.

## Oracle Cloud ingress (required once)

The NixOS firewall is already open (`openFirewall` for 25565, explicit UDP 24454), but Oracle's VCN blocks everything not listed in its security rules. Until those exist, clients time out and the server log shows no join attempt.

Console: **Networking -> Virtual Cloud Networks -> <VCN> -> Security Lists** (or the instance's NSG) -> **Add Ingress Rules**:

| Source | IP Protocol | Destination Port Range | Description |
|---|---|---|---|
| `0.0.0.0/0` | TCP | `25565` | Minecraft |
| `0.0.0.0/0` | UDP | `24454` | Simple Voice Chat |

Same for the IPv6 range (`::/0`) if clients connect over v6. Rules are stateless off by default, which is correct here.

Narrow the source to your own addresses if the server should not be public.

## Verify

```bash
# from a client
nc -vz <obox-ip> 25565

# on obox
systemctl status minecraft-server-obox
sudo ss -lntup | grep -E '25565|24454'
sudo iptables -L nixos-fw -n | grep -E '25565|24454'
sudo tail -40 /srv/minecraft/obox/logs/latest.log
```

| Symptom | Cause |
|---|---|
| `nc` times out | Oracle ingress rule missing |
| `nc` succeeds, client kicked after connect | account not in the whitelist |
| `ss` shows the listener, `latest.log` shows no join line | traffic never arrives (ingress) |

## Whitelist

Add the account (name -> UUID) to `modules/nixos/minecraft/users.nix`, then deploy obox:

```nix
services.minecraft-servers.servers.obox.whitelist = {
  semi710 = "5be37ebc-b9ce-3a44-b466-e338676d275d";
  someName = "<uuid>";
};
```

UUID of an offline-mode account: `nix shell nixpkgs#minecraft-server --command java -jar ...` is overkill; use the offline UUID formula (MD5 of `OfflinePlayer:<name>`) or let the server print it in `latest.log` on the first rejected join.
