{ pkgs, ... }:
let
  manifest = import ../../manifest.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos.nix
  ];

  users.users.${manifest.username} = {
    isNormalUser = true;
    description = manifest.fullName;
    extraGroups = [ "wheel" "audio" "video" ];
    hashedPassword = null;
    shell = pkgs.fish;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${manifest.username} = import ../../modules/home.nix;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
