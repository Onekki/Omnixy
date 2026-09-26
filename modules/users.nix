{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user or { };
  name = user.name or "omnixy";
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
      description = user.fullName or "Omnixy";
      extraGroups = [ "audio" "video" "wheel" ] ++ (user.extraGroups or [ ]);
      hashedPassword = user.hashedPassword or null;
      shell = pkgs.fish;
    };
  };
}
