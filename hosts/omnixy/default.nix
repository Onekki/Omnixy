{ ... }:
let
  manifest = import ../../config/omnixy.nix;
  enabledModules = manifest.enabledModules or [ "core" "denial" "rime" ];
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${manifest.user.name or "onekki"} = import ../../home/user.nix;
  };

  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system.nix
      ../../modules/users.nix
    ]
    ++ builtins.map (name: ../../modules/${name}.nix) enabledModules;

  # 默认按 UEFI + systemd-boot 配置；BIOS 机器请改成 grub。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
