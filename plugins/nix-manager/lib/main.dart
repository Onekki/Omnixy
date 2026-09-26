import 'dart:io';

import 'package:denial_dart_shell/denial.dart';
import 'package:flutter/widgets.dart';

import 'dashboard.dart';

void main() {
  final envRepository = Platform.environment['NIX_MANAGER_REPO'];
  final repository = envRepository ??
      (Directory.current.path.endsWith(
    '${Platform.pathSeparator}nix-manager',
      )
      ? Directory.current.parent.parent.path
      : Directory.current.path);

  runDenialShell(
    shell: DenialShell(
      mobile: const DenialShellScene(content: ShellWallpaper()),
      desktop: DenialShellScene(
        content: NixManagerDashboardScene(repoRoot: repository),
      ),
    ),
  );
}
