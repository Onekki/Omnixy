{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user or { };
  name = user.name or "omnixy";
in
{
  config = lib.mkIf (name != "") {
    users.users.${name} = {
      isNormalUser = true;
      description = user.fullName or "Omnixy";
      extraGroups = [ "audio" "video" "wheel" ] ++ (user.extraGroups or [ ]);
      hashedPassword = user.hashedPassword or null;
      shell = pkgs.fish;
    };
  };
}
