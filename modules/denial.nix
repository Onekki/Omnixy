{ config, ... }:
{
  programs.denial.enable = true;
  hardware.graphics.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.denial.package}/bin/denial-session --start-locked";
        user = "onekki";
      };
    };
  };
}
