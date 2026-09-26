# nix-manager

Nix Manager 的 Denial 原生界面工作区，入口与 Denial 官方
`dart_shell/example/custom_shell.dart` 保持一致。

当前是骨架：`lib/main.dart` 已经调用 `runDenialShell`。旧的自定义配置中心
（自定义配置中心）已随架构精简移除，dashboard 正在
改为直接读取 NixOS 求值结果或标准模块配置，不再维护私有配置表。

结构上已经包含：

- `lib/src/nix_manager_store.dart`：Nix 子集解析器、序列化器。
- `lib/src/nix_helper.dart`：`nix search nixpkgs`、`nix registry list`、`nixos-rebuild` 调用。
- `lib/dashboard.dart`：系统/用户/模块开关/软件包搜索/保存/构建的基础界面。

## 构建位置

这个工作区需要和 Denial 源码里的 `dart_shell` 平级，因为
`pubspec.yaml` 用 `path: ../dart_shell` 引用 `denial_dart_shell`：

```text
denial/
├── dart_shell/
└── plugins/
    └── nix-manager/
```

不过不要改 Denial 仓库本体。更合适的做法是在 Nix Manager flake 里把
`denial` 输入源码与 `nix-manager` 合成一个只读源码树，再用
`denial.packages.x86_64-linux.denial-flutter.buildFlutterApplication`
构建，类似官方 `nix/settings-app.nix`。

最终入口是：Denial 启动器里出现 Nix Manager。它用 `dart:io`
和 `Process.run` 调用 nix 命令，不依赖任何中间服务。
