{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user;
  userName = user.name;
  coreEnabled = builtins.elem "core" manifest.enabledModules;
  rimeEnabled = builtins.elem "rime" manifest.enabledModules;
in
{
  options.programs.omnixy.enable = lib.mkEnableOption "the Omnixy home configuration";

  config = lib.mkIf config.programs.omnixy.enable {
    home = {
      inherit userName;
      homeDirectory = "/home/${userName}";
      stateVersion = "26.05";
    };

    home.packages = lib.mkIf coreEnabled (with pkgs; [
      bat
      btop
      curl
      fd
      git
      jq
      kitty
      neovim
      ripgrep
      unzip
    ]);

    programs.fish.enable = coreEnabled;
    programs.starship.enable = coreEnabled;
    programs.kitty.enable = coreEnabled;

    programs.git = {
      enable = coreEnabled;
      userName = user.fullName;
    };

    home.file = lib.mkIf rimeEnabled {
      ".local/share/fcitx5/rime/default.custom.yaml".source =
        ../config/rime/default.custom.yaml;
      ".local/share/fcitx5/rime/luna_pinyin_simp.custom.yaml".source =
        ../config/rime/luna_pinyin_simp.custom.yaml;
      ".config/fcitx5/profile".text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=rime

        [Groups/0/Items/0]
        Name=keyboard-us
        Layout=

        [Groups/0/Items/1]
        Name=rime
        Layout=

        [GroupOrder]
        0=Default
      '';
      ".config/fcitx5/config".text = ''
        [Hotkey]
        Enumerate IM=Control+Shift+space
        Activate IM=Control+space
      '';
    };
  };
}
