import 'dart:io';

import 'package:denial_dart_shell/denial.dart';
import 'package:flutter/widgets.dart';

import 'dashboard.dart';

void main() {
  final envRepository = Platform.environment['OMNIXY_REPO'];
  final repository = envRepository ??
      (Directory.current.path.endsWith(
    '${Platform.pathSeparator}shell',
      )
      ? Directory.current.parent.path
      : Directory.current.path);

  runDenialShell(
    shell: DenialShell(
      mobile: const DenialShellScene(content: ShellWallpaper()),
      desktop: DenialShellScene(
        content: OmnixyDashboardScene(repoRoot: repository),
      ),
    ),
  );
}
