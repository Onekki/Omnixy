{ config, lib, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "denial" (manifest.enabledModules or [ ]);
  denial = manifest.settings.denial or { };
  displayManager = denial.displayManager or "gdm";
  autologin = denial.autologin or false;
  userName = (manifest.user or { }).name or "omnixy";
in
{
  config = lib.mkMerge [
    (lib.mkIf enabled {
      programs.denial = {
        enable = true;
        ddc.enable = true;
        polkitAgent.enable = true;
      };

      hardware.graphics.enable = true;
    })

    (lib.mkIf (enabled && displayManager != "none") {
      services.xserver.enable = true;

      services.displayManager = {
        defaultSession = "denial";
        sddm.enable = displayManager == "sddm";
        gdm.enable = displayManager == "gdm";
        autoLogin = lib.mkIf autologin {
          enable = true;
          user = userName;
        };
      };
    })
  ];
}
