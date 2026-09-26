{
  description = "Omnixy: an Omarchy-flavoured NixOS configuration built on Denial";

  nixConfig = {
    extra-substituters = [ "https://denial.cachix.org" ];
    extra-trusted-public-keys = [
      "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
    ];
  };

  inputs = {
    # Omnixy 默认跟踪 unstable，系统软件均为最新版。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    denial.url = "github:denialwm/denial";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs =
    inputs@{ nixpkgs, denial, ... }:
    let
      # Denial currently publishes only x86_64-linux Nix outputs.
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.omnixy = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          denial.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          ./hosts/omnixy
        ];
      };
    };
}
