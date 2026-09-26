# Omnixy

## 是什么

Omnixy 是一套以 NixOS 为底座、以 Denial 为桌面、以 Flutter 原生应用为配置界面的模块化配置仓库。

**技术栈**

- NixOS flake：`nixpkgs` 默认跟踪 `nixos-unstable`，系统软件保持最新，并通过 `flake.lock` 锁定版本。
- Denial：Flutter-native Wayland 合成器，官方 NixOS 模块负责构建引擎、注册会话、portal、Xwayland、polkit 等。
- 配置文件：`config/omnixy.nix`，一个结构化的 Nix attrset，由 bootstrap 在每台机器上生成，不再写死在仓库里。
- 原生 Shell：`shell/` 是 Denial custom shell 工作区，用 Dart 直接读写配置、调用 nix 命令，不依赖浏览器或 HTTP 服务。

**内置能力**

- Denial 桌面：默认 SDDM 登录，可选 GDM 或不用 display manager；支持自动登录；`session.conf` 与 `outputs.conf` 声明式管理。
- Rime 中文输入：fcitx5 的 Wayland 前端 + 朙月拼音简化字；默认中文输入，`Ctrl+Space` 切换中英文，`Ctrl+Shift+Space` 切换输入法。
- 核心工具：kitty、fish、neovim、git、curl、jq、bat、fd、ripgrep、btop、unzip；pipewire、中文字体、dconf、GVfs、udisks2 已随核心模块启用。
- 系统与用户：主机名、时区、locale、NetworkManager、用户账号、密码哈希、附加用户组。
- 模块机制：每个模块由 `modules/<id>.nix` 和 `modules/<id>.meta.nix` 自描述；`config/omnixy.nix` 的 `enabledModules` 决定动态导入哪些模块，shell 启动时扫描 meta 自动发现。

默认只启用 `core`、`denial`、`rime` 三个模块。浏览器、主题、游戏、AI、服务等都属于可选模块，需要时再开启。

## 为什么

- NixOS 让系统变成可复现的声明式配置：升级是可原子切换的，出问题可以回滚到上一个 generation。
- Denial 提供完全原生的 Flutter 桌面 Shell，因此配置界面可以做成 Denial 里的原生应用，而不是必须装浏览器才能打开的网页。
- 模块化而不是一步到位：Omnixy 刻意不像 Omarchy 那样把大量功能一次性塞给所有人，默认保持小核心，把选择权交给用户。
- 机器相关配置不入库：`hardware-configuration.nix` 和 `config/omnixy.nix` 都是安装时生成的，git 里只有模板、默认逻辑和模块代码。
- 默认跟踪 unstable：想要最新软件直接可用；如果希望更稳，把 `flake.nix` 里的 `nixpkgs.url` 换成 stable 分支，再跑 `nix flake update`。

## 怎么做

### 1. 准备

安装 NixOS（当前 Denial 只提供 `x86_64-linux` 输出）。安装器里创建的用户名会作为后续的默认用户名使用。

### 2. 获取仓库

把仓库放进系统，例如：

```bash
git clone https://github.com/Onekki/Omnixy.git
cd Omnixy
```

### 3. 配置生成策略

bootstrap 首次运行时会用内嵌默认模板生成 `config/omnixy.nix`，取值如下：

| 项目 | 默认来源 | 覆盖变量 |
| --- | --- | --- |
| 主机名 | `hostnamectl --static` | `OMNIXY_HOSTNAME` |
| 用户名 | 执行 sudo 的当前用户 | `OMNIXY_USER` |
| 时区 | `/etc/localtime` 符号链接 | `OMNIXY_TIMEZONE` |
| locale | `en_US.UTF-8` | `OMNIXY_LOCALE` |

例如：

```bash
sudo OMNIXY_HOSTNAME=myhost OMNIXY_USER=me bash scripts/bootstrap.sh
```

### 4. 生成硬件配置

```bash
sudo nixos-generate-config
```

### 5. 构建系统

```bash
sudo bash scripts/bootstrap.sh
```

这个脚本会依次完成：

1. 如果没有 `config/omnixy.nix`，根据当前机器和覆盖变量生成它；
2. 如果 `hosts/omnixy/hardware-configuration.nix` 不存在，就从 `/etc/nixos/hardware-configuration.nix` 复制；
3. 如果还没有 `flake.lock`，先执行 `nix flake update`；
4. 执行 `nixos-rebuild switch --flake .#omnixy`。

注意：Denial 缓存未命中时需要从源码构建 Flutter engine，官方建议准备至少 64 GiB 的临时存储空间。

### 6. 重启登录

重启后在 SDDM 登录界面选择 **Denial**。

`config/omnixy.nix` 默认 `hashedPassword = null`：安装器创建的同名用户会保留原密码，登录后可以用 `passwd` 修改；想声明式设置密码，就先生成哈希：

```bash
mkpasswd -m sha-512
```

然后把结果填进 `config/omnixy.nix` 的 `user.hashedPassword`，再重新构建。

### 7. 日常修改

机器生成后的 `config/omnixy.nix` 是主要编辑入口，分为四块：

- `system`：主机名、时区、locale、NetworkManager；
- `user`：用户名、全名、密码哈希、附加组；
- `enabledModules`：启用哪些模块；
- `settings`：每个模块自己的可配置项。

修改后重新构建：

```bash
sudo bash scripts/bootstrap.sh
```

### 8. 添加和删除模块

一个模块只需要两个文件：

```text
modules/<id>.nix
modules/<id>.meta.nix
```

`<id>.meta.nix` 描述名称、说明和设置项；`<id>.nix` 实现模块逻辑。shell 会扫描 meta 自动发现模块，并在原生界面里提供“添加模块”和“删除模块”按钮，不再需要手动创建或删除文件；手动写这两个文件的效果也一样。内置模块只能停用，不能删除。

### 9. 原生配置界面

`shell/` 是 Denial 原生 dashboard 工作区，目标是在 Denial 启动器里直接打开配置界面，界面内可以：

- 编辑系统与用户设置；
- 开关模块；
- 添加和删除自定义模块；
- 搜索 nixpkgs 软件包；
- 调用 `nix registry list` 搜索 flake；
- 保存并触发系统重建。

当前 `shell/` 已经包含 Dart 的配置读写、Nix 解析/序列化和 nix 命令调用代码；由于需要 Denial 锁定的 Flutter 工具链，最终编译和桌面集成在 NixOS 上完成。

### 10. 更新

```bash
cd Omnixy
nix flake update
sudo bash scripts/bootstrap.sh
```

`flake.lock` 决定了软件版本是否漂移；不主动 `nix flake update`，构建就始终使用锁定版本。
