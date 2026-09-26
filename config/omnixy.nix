{
  system = {
    hostname = "omnixy";
    timezone = "Asia/Shanghai";
    locale = "en_US.UTF-8";
    networkManager = true;
  };
  user = {
    name = "onekki";
    fullName = "Onekki";
    hashedPassword = null;
    extraGroups = [ ];
  };
  enabledModules = [ "core" "denial" "rime" ];
  settings = {
    core = { };
    denial = {
      displayManager = "sddm";
      autologin = false;
    };
    rime = {
      overwrite = false;
    };
  };
}
