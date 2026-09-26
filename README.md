# Omnixy

## 是什么

Omnixy 是一套以 NixOS 为底座、以 Denial 为桌面、以 Flutter 原生应用为配置界面的配置仓库。它使用标准 flake + Home Manager 工作流，不定义自定义 option 层，也不维护中央配置文件。

- `flake.nix`：`nixos-unstable` + `denial` + `home-manager`。
- `manifest.nix`：机器变量（用户名、主机名、时区、locale、镜像），改这里最快。
- `hosts/<machine>/default.nix`：每台机器的用户、Home Manager、bootloader 和硬件配置。
- `modules/`：一个模块一个文件，或者一个目录（`default.nix` 入口）。`modules/nixos.nix` 是系统入口，聚合 `core`、`denial`、`rime`。
- `modules/home.nix`：Home Manager 入口，管理用户软件包、fish、kitty、git、Rime 与 fcitx5 的用户配置。
- `modules/rime/home.nix`：Rime/fcitx5 的用户文件配置（YAML/INI 由 Nix 生成），随 Rime 模块走。
- `plugins/nix-manager/`：Denial 原生设置界面工作区（Nix Manager）。

## 为什么

- NixOS 提供声明式配置和原子回滚。
- Denial 提供原生 Flutter 桌面与锁屏入口，不需要浏览器。
- 不使用自定义配置中心：机器差异直接写在 `hosts/`，系统差异直接写在标准 NixOS 选项里，别人接手时不需要先学一套私有概念。

## 怎么做

1. 安装 NixOS。
2. 获取仓库：

   ```bash
   git clone https://github.com/Onekki/Omnixy.git
   cd Omnixy
   ```

3. 一键安装新机器：

   ```bash
   sudo bash scripts/setup.sh
   ```

   setup 会自动：准备 git、生成 `hosts/omnixy/hardware-configuration.nix`、生成 `flake.lock`，然后执行 `nixos-rebuild switch`。

4. 按需修改机器配置：

   - `manifest.nix`：用户名、主机名、时区、locale、镜像等变量，其他用户改这里最快。
   - `hosts/omnixy/default.nix`：用户名、用户组、Home Manager 用户、bootloader。
   - `modules/core.nix`：基础服务，主机名/时区/locale/镜像走 `manifest.nix`。
   - `modules/denial.nix`：Denial 与 greetd 锁屏入口。
   - `modules/rime/`：fcitx5 + Rime 系统侧配置。

5. 日常重建：

   ```bash
   nrs
   ```

   `nrs` 是 Home Manager 生成的快捷方式（bash/zsh alias，fish 函数），等价于上面的 rebuild 命令。

6. 多台机器：`hosts/` 下每个目录自动生成一个配置，构建时把 `#omnixy` 换成对应机器名。
7. 重启后 greetd 拉起 Denial，用 Denial 原生锁屏解锁。
8. 日常修改：直接编辑 `hosts/` 和 `modules/`，再重建。`plugins/nix-manager/` 会在 NixOS 上以原生界面接入这些配置。
