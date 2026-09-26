{ ... }:
let
  manifest = import ../config/omnixy.nix;
  enabledModules = manifest.enabledModules;
  userName = manifest.user.name;
in
{
  imports =
    [
      ../modules/system.nix
      ../modules/users.nix
    ]
    ++ builtins.map (name: ../modules/${name}.nix) enabledModules;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${userName} = import ../home/user.nix;
  };

  # 默认按 UEFI + systemd-boot 配置；BIOS 机器请改成 grub。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
