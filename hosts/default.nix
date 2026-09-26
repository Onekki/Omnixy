{ ... }:
let
  manifest = import ../config/omnixy.nix;
  userName = manifest.user.name;
in
{
  imports = [ ../modules/nixos.nix ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${userName} = {
      imports = [ ../modules/home.nix ];
      programs.omnixy.enable = true;
    };
  };

  # 默认按 UEFI + systemd-boot 配置；BIOS 机器请改成 grub。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
