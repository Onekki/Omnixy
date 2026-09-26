import 'dart:convert';
import 'dart:io';

class PackageHit {
  final String attr;
  final String name;
  final String version;
  final String description;

  PackageHit({
    required this.attr,
    required this.name,
    required this.version,
    required this.description,
  });
}

Future<List<PackageHit>> searchNixpkgs(String query) async {
  final result = await Process.run(
    'nix',
    ['search', 'nixpkgs', '--json', query],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString().trim());
  }
  final raw =
      jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
  final hits = <PackageHit>[];
  final seen = <String>{};
  raw.forEach((key, info) {
    final infoMap = info is Map ? Map<String, dynamic>.from(info) : <String, dynamic>{};
    final attr = key.split('.').last;
    if (seen.contains(attr)) return;
    seen.add(attr);
    hits.add(PackageHit(
      attr: attr,
      name: (infoMap['pname'] as String?) ?? attr,
      version: (infoMap['version'] as String?) ?? '',
      description: (infoMap['description'] as String?) ?? '',
    ));
  });
  hits.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return hits.take(80).toList();
}

String normalizeFlakeUrl(String input) {
  final trimmed = input.trim();
  final githubMatch = RegExp(
    r'^https?://github\.com/([^/?#]+)/([^/?#]+)',
  ).firstMatch(trimmed);
  if (githubMatch == null) return trimmed;

  final owner = githubMatch.group(1)!;
  var repo = githubMatch.group(2)!.replaceFirst(RegExp(r'\.git$'), '');
  final tail = trimmed.substring(githubMatch.end).split('?').first;
  final tailParts =
      tail.split('/').where((part) => part.isNotEmpty).toList();
  if (tailParts.isNotEmpty &&
      tailParts.first == 'tree' &&
      tailParts.length >= 2) {
    return 'github:$owner/$repo/${tailParts[1]}';
  }
  return 'github:$owner/$repo';
}

Future<List<Map<String, String>>> searchFlakes(String query) async {
  final result = await Process.run(
    'nix',
    ['registry', 'list'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString().trim());
  }
  final items = <Map<String, String>>[];
  for (final line in result.stdout.toString().split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 3 || !parts[1].startsWith('flake:')) continue;
    final name = parts[1].substring('flake:'.length);
    final url = parts[2];
    final matched =
        query.isEmpty ||
        name.toLowerCase().contains(query.toLowerCase()) ||
        url.toLowerCase().contains(query.toLowerCase());
    if (matched) items.add({'name': name, 'url': url});
  }
  items.sort((a, b) => a['name']!.compareTo(b['name']!));
  return items.take(60).toList();
}

Future<String> rebuild(String repoRoot) async {
  final host = Platform.environment['NIX_MANAGER_HOST'] ?? 'omnixy';
  final result = await Process.run(
    'sudo',
    ['nixos-rebuild', 'switch', '--flake', 'path:$repoRoot#$host'],
    environment: {
      'NIX_CONFIG': 'experimental-features = nix-command flakes',
    },
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString().trim());
  }
  return result.stdout.toString();
}
