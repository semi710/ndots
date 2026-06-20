{
  disko = {
    devices = {
      disk = {
        primary = {
          content = {
            partitions = {
              _type = "merge";
              contents = [
                {
                  ESP = {
                    content = {
                      format = "vfat";
                      mountOptions = [
                        "defaults"
                        "umask=0077"
                      ];
                      mountpoint = "/boot";
                      type = "filesystem";
                    };
                    size = "512M";
                    type = "EF00";
                  };
                }
                {
                  _type = "if";
                  condition = true;
                  content = {
                    root = {
                      content = {
                        subvolumes = {
                          _type = "merge";
                          contents = [
                            {
                              "/nix" = {
                                mountOptions = [
                                  "compress=zstd"
                                  "noatime"
                                  "noacl"
                                ];
                                mountpoint = "/nix";
                              };
                              "/root" = {
                                mountOptions = [ "compress=zstd" ];
                                mountpoint = "/";
                              };
                            }
                            {
                              _type = "if";
                              condition = false;
                              content = {
                                "/persistent" = {
                                  mountOptions = [ "compress=zstd" ];
                                  mountpoint = "/persistent";
                                };
                              };
                            }
                          ];
                        };
                        type = "btrfs";
                      };
                      size = "100%";
                      type = "8300";
                    };
                  };
                }
                {
                  _type = "if";
                  condition = false;
                  content = {
                    root = {
                      content = {
                        content = {
                          extraArgs = [ "-f" ];
                          subvolumes = {
                            _type = "merge";
                            contents = [
                              {
                                "/nix" = {
                                  mountOptions = [
                                    "compress=zstd"
                                    "noatime"
                                    "noacl"
                                  ];
                                  mountpoint = "/nix";
                                };
                                "/root" = {
                                  mountOptions = [ "compress=zstd" ];
                                  mountpoint = "/";
                                };
                              }
                              {
                                _type = "if";
                                condition = false;
                                content = {
                                  "/persistent" = {
                                    mountOptions = [ "compress=zstd" ];
                                    mountpoint = "/persistent";
                                  };
                                };
                              }
                            ];
                          };
                          type = "btrfs";
                        };
                        name = "cryptroot";
                        settings = {
                          allowDiscards = true;
                        };
                        type = "luks";
                      };
                      size = "100%";
                    };
                  };
                }
              ];
            };
            type = "gpt";
          };
          device = "/dev/sda";
          type = "disk";
        };
      };
    };
  };
}
