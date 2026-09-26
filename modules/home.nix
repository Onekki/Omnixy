{ pkgs, ... }:
{
  home = {
    username = "onekki";
    homeDirectory = "/home/onekki";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [
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
  ];

  programs.fish.enable = true;
  programs.starship.enable = true;
  programs.kitty.enable = true;

  programs.git = {
    enable = true;
    userName = "Onekki";
  };

  home.file = {
    ".local/share/fcitx5/rime/default.custom.yaml".source =
      ./rime/config/default.custom.yaml;
    ".local/share/fcitx5/rime/luna_pinyin_simp.custom.yaml".source =
      ./rime/config/luna_pinyin_simp.custom.yaml;
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
}
