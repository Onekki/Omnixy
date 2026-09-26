{
  core = {
    name = "核心工具";
    description = "kitty、fish、neovim、git、ripgrep 等最小工具集";
    builtin = true;
    settings = [ ];
  };
  denial = {
    name = "Denial 桌面";
    description = "Wayland 合成器与默认会话";
    builtin = true;
    settings = [
      {
        key = "displayManager";
        label = "显示管理器";
        type = "select";
        options = [ "greetd" "gdm" "sddm" "none" ];
        default = "greetd";
      }
      {
        key = "autologin";
        label = "自动登录";
        type = "bool";
        default = false;
      }
    ];
  };
  rime = {
    name = "Rime 中文输入";
    description = "fcitx5 + 朙月拼音简化字";
    builtin = true;
    settings = [ ];
  };
}
