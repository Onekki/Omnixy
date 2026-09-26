{ config, lib, ... }:
{
  options.programs.omnixy.enable = lib.mkEnableOption "the Omnixy NixOS desktop";

  imports = [
    ./system.nix
    ./users.nix
    ./core.nix
    ./services/denial.nix
    ./services/rime.nix
  ];
}
