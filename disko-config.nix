{ swapSize ? "17GiB", device ? "/dev/sda" }:
{
  disk = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        bios = {
          priority = 0;
          size = "1MiB";
          type = "EF02";
        };
        boot = {
          priority = 1;
          size = "512MiB";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        swap = {
          priority = 2;
          size = swapSize;
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@".mountpoint = "/";
              "@home".mountpoint = "/home";
              "@snapshots".mountpoint = "/.snapshots";
            };
          };
        };
      };
    };
  };
}
