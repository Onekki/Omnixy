# Omnixy

Omnixy 是一个受 [Omarchy](https://github.com/omacom/omarchy) 启发的 NixOS 配置仓库：提供一组开箱即用的、有主见的模块，并把 [Denial](https://github.com/denialwm/denial) 这个 Wayland 合成器作为默认桌面会话。

当前骨架包含：

- `flake.nix`：锁定 `nixpkgs`（默认跟踪 `nixos-unstable`）与 `denial` 输入，并在 flake 顶层配置 `denial.cachix.org` 二进制缓存。
- `hosts/omnixy/`：主机入口与 `hardware-configuration.nix` 占位文件。
- `modules/`：Denial 会话、核心工具链、Rime 中文输入法、用户管理模块。
- `modules/*.meta.nix`：模块自描述文件，Omnixy shell 扫描它们自动发现模块。
- `config/denial/`：声明式的 `session.conf` 与 `outputs.conf` 模板。
- `config/rime/`：Rime 的 `luna_pinyin_simp` 种子配置。
- `config/omnixy.nix`：Omnixy shell 生成的结构化 Nix 配置，Nix 模块直接 `import` 它。
- `shell/`：Denial 原生 dashboard 工作区，直接用 Dart 读写配置和调用 Nix CLI，不依赖网页或后端服务。

## 快速开始

适合已经装好 NixOS 、或者只是想先跑通配置流程的练习环境。

1. 安装 NixOS（推荐直接用官方图形安装器，安装时把用户名填成你要用的账号）。
2. 在已安装的 NixOS 系统里准备好这份仓库（可以通过 git clone 或从 U 盘复制进去）。
3. 填写主机名、用户名、时区等配置。Denial 原生 dashboard 完成前，直接编辑 `config/omnixy.nix`，Nix 模块直接 `import` 这份 attrset。
4. 生成真实硬件配置：

   ```bash
   sudo nixos-generate-config
   ```

5. 为用户生成密码哈希并填到 `config/omnixy.nix` 的 `user.hashedPassword`：

   ```bash
   mkpasswd -m sha-512
   ```

   也可以保留 `null`：安装时用图形安装器创建同名用户并保留密码，rebuild 后直接用原密码登录，登录后再执行 `passwd` 改密码。

6. 一键构建并切换（会自动复制硬件配置、生成 flake.lock、再执行 rebuild）：

   ```bash
   sudo bash scripts/bootstrap.sh
   ```

   Omnixy 默认跟踪 `nixos-unstable`。想固定在某次提交或某个 stable 分支时，改 `flake.nix` 里的 `nixpkgs.url` 并重新 `nix flake update` 即可。

7. 重启后在 SDDM 登录界面选择 **Denial**。

> 小白最容易漏的三件事：`hardware-configuration.nix` 必须是真实机器生成的；用户名在 `config/omnixy.nix` 里改成自己的；密码要么填哈希，要么装完后用 `passwd` 设置。

## Denial 原生配置

Omnixy 的所有常规设置放在 `config/omnixy.nix`，它是结构化的 Nix attrset：`system`、`user`、`enabledModules` 列表，以及每个模块自己的 `settings`。不再有网页面板，也不再有 HTTP 配置服务；这些能力全部由 `shell` 里的 Dart 直接实现：

- `dart:io` 读写 `config/omnixy.nix` 和 `modules/*.meta.nix`；
- 用 Dart 内置的 Nix 子集解析器/序列化器生成结构化 Nix 代码；
- 用 `Process.run` 调用 `nix search nixpkgs`、`nix registry list` 和 `nixos-rebuild`。

新增一个模块不需要改 Dart：写 `modules/<id>.nix` + `modules/<id>.meta.nix`，shell 启动时扫描自动发现。自定义模块可以在原生界面里删除，内置模块只能停用。

## 软件包与 Flake 搜索

Omnixy shell 支持两类搜索：

- nixpkgs 搜索：Dart 调用本机 `nix search nixpkgs <关键词>`，命中的软件包一键变成 `pkg-<名称>` 模块并自动启用。
- flake 搜索：Dart 调用 `nix registry list` 搜索注册表，也可以直接填写 `github:owner/repo`；写入 `flake.nix`、通过 `specialArgs` 把 `inputs` 传给模块，并生成 `flake-<名称>` 模块骨架。

搜索依赖系统里的 nix CLI；在没有 Nix 的机器上会返回明确提示，不会破坏配置。

## 中文输入法（Rime）

Omnixy 通过 Fcitx5 的 Wayland 前端接入 Rime。Fcitx5 profile 里显式注册了英文 `keyboard-us` 和中文 `rime` 两个输入法，并把 `rime` 设为默认，因此开箱就是中文输入；`Ctrl+Space` 切换中英文，`Ctrl+Shift+Space` 切换输入法，Rime 内也可以按 `Shift` 临时进入英文。Denial 自己实现了 `zwp_input_method_manager_v2`，候选框由 Denial 的 shell 绘制，不需要 layer-shell。

Rime 的输入方案写在 `config/rime/`：

- `default.custom.yaml`：默认启用 `luna_pinyin_simp` 方案。
- `luna_pinyin_simp.custom.yaml`：中英文形态默认中文，并带全半角、简繁、全半角标点与 Shift 切换。

执行 `nixos-rebuild` 时，这些文件会在用户首次进入系统前种子到 `~/.local/share/fcitx5/rime/`。日常手工修改会保留；如果需要让每次 rebuild 都覆盖回仓库里的版本，把 `settings.rime.overwrite` 设为 `true`。

## Denial 集成

Denial 官方 NixOS 模块负责构建 Rust 合成器、锁定的 Flutter 引擎、内嵌 shell 与 Settings，并注册 Wayland session、Settings portal、wlroots 截屏/录屏 portal、Xwayland、polkit 与实时调度。

官方模块刻意不启用 display manager、不设置默认 session、也不做自动登录。Omnixy 在 `modules/denial.nix` 里补上这部分行为，开关和选项都来自 `config/omnixy.nix`：

```nix
{
  enabledModules = [ "core" "denial" "rime" ];
  settings = {
    denial = {
      displayManager = "sddm";
      autologin = false;
    };
  };
}
```

`config/denial/outputs.conf` 是声明式的系统默认输出配置；Denial 会在没有可写用户配置时把它同步到 `$XDG_STATE_HOME/denial/outputs.conf`。日常显示器调整仍然可以写到 `~/.config/denial/outputs.conf`。

注意：Denial 缓存命中时下载预构建产物，缓存未命中则要从源码构建锁定的 Flutter engine，官方文档建议准备至少 64 GiB 的临时存储空间。

## 目录结构

```text
.
├── flake.nix
├── config/
│   ├── omnixy.nix
│   ├── denial/
│   │   ├── outputs.conf
│   │   └── session.conf
│   └── rime/
│       ├── default.custom.yaml
│       └── luna_pinyin_simp.custom.yaml
├── hosts/
│   └── omnixy/
│       ├── default.nix
│       └── hardware-configuration.nix
├── scripts/
│   └── bootstrap.sh
└── modules/
    ├── core.meta.nix
    ├── core.nix
    ├── denial.meta.nix
    ├── denial.nix
    ├── rime.meta.nix
    ├── rime.nix
    ├── system.nix
    └── users.nix
├── shell/
│   ├── lib/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── README.md
```

## 设计取向

Omnixy 刻意不复制 Omarchy 那种“全都要”的发行版：默认只保留核心桌面体验（Denial、Rime、基础工具），其余功能按模块拆开，用户按需启用，而不是默认全装。

## 可选扩展（默认不启用）

- `modules/home-manager.nix`：管理 dotfiles（fish、kitty、git、ssh、neovim、tmux）。
- `modules/browsing.nix`：浏览器与浏览器策略。
- `modules/theming.nix`：壁纸、SDDM/Plymouth、图标与终端配色。
- `modules/desktop-utils.nix`：截图、剪贴板历史、通知等。
- `modules/gaming.nix`、`modules/ai.nix`、`modules/services.nix`：Omarchy 式重功能全部做成可选。
