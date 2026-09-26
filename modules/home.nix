{ pkgs, ... }:
let
  manifest = import ../manifest.nix;
in
{
  imports = [ ./rime/home.nix ];

  home = {
    username = manifest.username;
    homeDirectory = "/home/${manifest.username}";
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

  programs.fish.functions.nrs = {
    description = "Rebuild the current Omnixy host";
    body = ''
      sudo nixos-rebuild switch --flake "path:$PWD#omnixy"
    '';
  };

  home.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake \"path:$PWD#omnixy\"";
  };

  programs.git = {
    enable = true;
    userName = manifest.fullName;
  };

}
