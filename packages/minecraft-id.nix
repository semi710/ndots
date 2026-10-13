{
  writers,
}:
# Offline-mode UUID for a Minecraft username: md5("OfflinePlayer:<name>")
# shaped into a UUIDv3 - the same deterministic derivation the server applies
# at join, so ids can be pinned into modules/nixos/minecraft/users.nix without
# the player ever connecting.
writers.writePython3Bin "minecraft-id" { } ''
  import hashlib
  import sys
  import uuid

  if len(sys.argv) < 2:
      sys.exit("usage: minecraft-id <username>...")

  for name in sys.argv[1:]:
      b = bytearray(hashlib.md5(f"OfflinePlayer:{name}".encode()).digest())
      b[6] = (b[6] & 0x0F) | 0x30  # UUID version 3
      b[8] = (b[8] & 0x3F) | 0x80  # RFC 4122 variant
      print(f'  {name} = "{uuid.UUID(bytes=bytes(b))}";')
''
