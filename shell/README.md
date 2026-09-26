# shell

Omnixy 的 Denial 原生界面工作区，入口与 Denial 官方
`dart_shell/example/custom_shell.dart` 保持一致。

当前是骨架：`lib/main.dart` 已经调用 `runDenialShell`，下一步在
`_OmnixyDesktopScene` 里用 Dart 直接实现配置管理，不再有网页或 HTTP 服务。

现在已经包含：

- `lib/src/omnixy_store.dart`：Nix 子集解析器、序列化器、读写 `config/omnixy.nix`、读取 `data/omnixy-modules.nix`。
- `lib/src/nix_helper.dart`：`nix search nixpkgs`、`nix registry list`、`nixos-rebuild` 调用。
- `lib/dashboard.dart`：系统/用户/模块开关/软件包搜索/保存/构建的基础界面。

## 构建位置

这个工作区需要和 Denial 源码里的 `dart_shell` 平级，因为
`pubspec.yaml` 用 `path: ../dart_shell` 引用 `denial_dart_shell`：

```text
denial/
├── dart_shell/
├── shell/
└── ...
```

不过不要改 Denial 仓库本体。更合适的做法是在 Omnixy flake 里把
`denial` 输入源码与 `shell` 合成一个只读源码树，再用
`denial.packages.x86_64-linux.denial-flutter.buildFlutterApplication`
构建，类似官方 `nix/settings-app.nix`。

最终入口是：Denial 启动器里出现 Omnixy Dashboard。它用 `dart:io`
直接读写 `config/omnixy.nix`，用 `Process.run` 调用 nix 命令，
不依赖任何中间服务。
