{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  user = manifest.user or { };
  userName = user.name or "onekki";
  coreEnabled = builtins.elem "core" (manifest.enabledModules or [ ]);
in
{
  home = {
    inherit userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "25.05";
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
    userName = user.fullName or "";
  };
}
