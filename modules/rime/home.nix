{ pkgs, ... }:
let
  rimeYaml = name: text: pkgs.writeText name text;
in
{
  home.file = {
    ".local/share/fcitx5/rime/default.custom.yaml".source =
      rimeYaml "default.custom.yaml" ''
        patch:
          schema_list:
            - schema: luna_pinyin_simp
      '';
    ".local/share/fcitx5/rime/luna_pinyin_simp.custom.yaml".source =
      rimeYaml "luna_pinyin_simp.custom.yaml" ''
        patch:
          switches:
            - name: ascii_mode
              reset: 0
              states: ["中文", "西文"]
            - name: full_shape
              reset: 0
              states: ["半角", "全角"]
            - name: simplification
              reset: 1
              states: ["漢字", "汉字"]
            - name: ascii_punct
              reset: 0
              states: ["。，", "．，"]
          engine:
            filters:
              - simplifier
              - uniquifier
          ascii_composer:
            switch_key:
              Shift_L: commit_code
              Shift_R: inline_ascii
      '';
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
