# Omnixy

## 是什么

Omnixy 是一套基于 NixOS 与 Denial 的桌面配置仓库。它把系统组织成可独立启用的模块，默认只提供核心桌面、Denial 会话和 Rime 中文输入，其余功能按需添加，并通过 Denial 原生 Shell 进行图形化管理。

## 为什么

选择这套组合，是因为 NixOS 提供声明式配置和原子回滚，Denial 提供不需要浏览器的 Flutter 原生桌面体验。Omnixy 刻意不像 Omarchy 那样把大量功能一次性塞给所有人，而是保持核心精简，把选择权留给用户。

## 怎么做

1. 安装 NixOS。
2. 把仓库放到系统里（例如 `git clone`）。
3. 生成硬件配置：

   ```bash
   sudo nixos-generate-config
   ```

4. 构建系统：

   ```bash
   sudo bash scripts/bootstrap.sh
   ```

   bootstrap 会复制硬件配置、生成 `config/omnixy.nix` 和 `flake.lock`，然后执行 `nixos-rebuild switch`。

5. 重启后，在 SDDM 登录界面选择 **Denial**。

日常修改集中在 `config/omnixy.nix`；图形化配置界面位于 `shell/`，由 Denial 原生启动。硬件配置和生成的 `config/omnixy.nix` 都不提交到 git。

bootstrap 前可以用 `OMNIXY_HOSTNAME`、`OMNIXY_USER`、`OMNIXY_TIMEZONE`、`OMNIXY_LOCALE` 覆盖默认值。
