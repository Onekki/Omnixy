# Omnixy

## 是什么

Omnixy 是一套以 NixOS 为底座、以 Denial 为桌面、以 Flutter 原生应用为配置界面的模块化配置仓库。

- NixOS flake：`nixpkgs` 默认跟踪 `nixos-unstable`，通过 `flake.lock` 锁定版本。
- Denial：Flutter-native Wayland 合成器，官方 NixOS 模块负责合成器、session、portal、Xwayland、polkit 等。
- 配置：`config/omnixy.nix` 是提交在仓库里的默认结构化 Nix attrset，机器专属值由你修改后提交。
- 原生 Shell：`shell/` 是 Denial custom shell 工作区，用 Dart 读写配置、调用 nix 命令，不依赖浏览器。

默认只启用 `core`、`denial`、`rime` 三个模块：核心工具、Denial 桌面、Rime 中文输入。浏览器、主题、游戏、AI、服务等作为可选模块按需开启。

## 为什么

- NixOS 提供声明式配置和原子回滚，系统状态可以完全由 flake 复现。
- Denial 提供原生 Flutter 桌面体验，配置界面可以做成 Denial 里的原生应用，不需浏览器。
- 模块化而不是全量捆绑：核心保持精简，功能模块按需启用。
- 直接 flake 工作流：`config/omnixy.nix` 提交到 git；`hardware-configuration.nix` 按机器生成并忽略，构建时用 `path:` 引用当前工作区，无需额外脚本。

## 怎么做

### 1. 准备

安装 NixOS（当前 Denial 只提供 `x86_64-linux` 输出）。

### 2. 获取仓库

```bash
git clone https://github.com/Onekki/Omnixy.git
cd Omnixy
```

### 3. 生成硬件配置

```bash
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix hosts/omnixy/hardware-configuration.nix
```

`hosts/omnixy/hardware-configuration.nix` 被 `.gitignore` 忽略，不入库。因为它未跟踪，git flake 的 `.#omnixy` 看不到它，构建要用 `path:` 引用工作区：

### 4. 调整默认配置

编辑 `config/omnixy.nix`，把主机名、用户名、时区、镜像等改成自己的：

```nix
{
  system = {
    hostname = "omnixy";
    timezone = "Asia/Shanghai";
    locale = "en_US.UTF-8";
    networkManager = true;
    mirror = "china";
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
      displayManager = "gdm";
      autologin = false;
    };
    rime = {
      overwrite = false;
    };
  };
}
```

`mirror` 支持 `china` 和 `global`；`china` 会启用 TUNA 二进制缓存。

### 5. 构建

全新系统需要先临时启用 flake 实验特性：

```bash
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  nixos-rebuild switch --flake "path:$PWD#omnixy"
```

系统已经配置好后，直接：

```bash
sudo nixos-rebuild switch --flake "path:$PWD#omnixy"
```

### 6. 重启登录

重启后在 SDDM 登录界面选择 **Denial**。密码可以先用安装器用户密码，登录后再 `passwd` 修改，或把哈希填进 `config/omnixy.nix` 的 `user.hashedPassword`。

### 7. 日常修改

- 改系统/用户/模块开关：编辑 `config/omnixy.nix` 或使用 Denial 原生 dashboard；
- 添加模块：写 `modules/<id>.nix` + `modules/<id>.meta.nix`，shell 会自动发现；
- 搜索 nixpkgs/flake：在 dashboard 里搜索并生成 `pkg-<名称>` / `flake-<名称>` 模块；
- 每次修改后执行 `sudo nixos-rebuild switch --flake "path:$PWD#omnixy"`。
