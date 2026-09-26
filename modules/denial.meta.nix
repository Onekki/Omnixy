{
  name = "Denial 桌面";
  description = "Wayland 合成器与默认会话";
  builtin = true;
  settings = [
    {
      key = "displayManager";
      label = "显示管理器";
      type = "select";
      options = [ "sddm" "gdm" "none" ];
      default = "sddm";
    }
    {
      key = "autologin";
      label = "自动登录";
      type = "bool";
      default = false;
    }
  ];
}
