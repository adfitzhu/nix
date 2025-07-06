{ pkgs, ... }: {
  home.stateVersion = "25.05";
 # services.nextcloud-client.enable = true;

  services.syncthing = {
    enable = true;
    overrideFolders = false;
    overrideDevices = false;
    settings = {
      devices = {
        "other-device" = {
          id = "MRRPBZ3-VNO336P-4MBXUJC-265FSLR-UTRAQHR-QWVKXAK-4AQGXHE-5XWTDAH";
        };
      };
      folders = {
        "d5vdra-wsih4" = {
          path = "/home/adam/Documents";
          devices = [ "MRRPBZ3-VNO336P-4MBXUJC-265FSLR-UTRAQHR-QWVKXAK-4AQGXHE-5XWTDAH" ];
          label = "Adam's Documents"; # This is the friendly name shown in the UI
        };
        "cn6bf-ym49z" = {
          path = "/home/adam/Music";
          devices = [ "MRRPBZ3-VNO336P-4MBXUJC-265FSLR-UTRAQHR-QWVKXAK-4AQGXHE-5XWTDAH" ];
          label = "Adam's Music"; # This is the friendly name shown in the UI
        };
      };
    };
  };
}
