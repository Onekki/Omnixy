{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user;
  name = user.name;
in
{
  config = lib.mkIf (name != "") {
    system.activationScripts.omnixy-user-local = {
      text = ''
        user=${lib.escapeShellArg name}
        install -d -o "$user" -g users -m 0755 "/home/$user/.local"
        install -d -o "$user" -g users -m 0755 "/home/$user/.local/state"
      '';
      deps = [ "users" ];
    };

    users.users.${name} = {
      isNormalUser = true;
      description = user.fullName;
      extraGroups = [ "audio" "video" "wheel" ] ++ user.extraGroups;
      hashedPassword = user.hashedPassword;
      shell = pkgs.fish;
    };
  };
}
