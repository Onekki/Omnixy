{ ... }:
{
  programs.fish.enable = true;

  programs.fish.functions.nrs = {
    description = "Rebuild the current Omnixy host";
    body = ''
      sudo nixos-rebuild switch --flake "path:$PWD#omnixy"
    '';
  };
}
