{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user;
  userName = user.name;
  coreEnabled = builtins.elem "core" manifest.enabledModules;
  rimeEnabled = builtins.elem "rime" manifest.enabledModules;
in
{
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
  };
}
