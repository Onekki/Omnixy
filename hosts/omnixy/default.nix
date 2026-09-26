{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos.nix
  ];

  users.users.onekki = {
    isNormalUser = true;
    description = "Onekki";
    extraGroups = [ "wheel" "audio" "video" ];
    hashedPassword = null;
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.onekki = import ../../modules/home.nix;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
