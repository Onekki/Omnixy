import 'dart:io';

class NixParseException implements Exception {
  final String message;
  NixParseException(this.message);

  @override
  String toString() => 'NixParseException: $message';
}

class ModuleSpec {
  final String id;
  final String name;
  final String description;
  final bool builtin;
  final List<Map<String, dynamic>> settings;

  ModuleSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.builtin,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'builtin': builtin,
        'settings': settings,
      };
}

class _Token {
  final String type;
  final String value;
  _Token(this.type, this.value);
}

class _Parser {
  final List<_Token> tokens;
  int position = 0;

  _Parser(this.tokens);

  dynamic parseValue() {
    final token = tokens[position];
    if (token.type == 'ident') {
      position++;
      if (token.value == 'true') return true;
      if (token.value == 'false') return false;
      if (token.value == 'null') return null;
      throw NixParseException('unexpected identifier ${token.value}');
    }
    if (token.type == 'str') {
      position++;
      return token.value;
    }
    if (token.type == '[') {
      position++;
      final items = <dynamic>[];
      while (tokens[position].type != ']') {
        items.add(parseValue());
      }
      position++;
      return items;
    }
    if (token.type == '{') {
      position++;
      final result = <String, dynamic>{};
      while (tokens[position].type != '}') {
        final keyToken = tokens[position];
        if (keyToken.type != 'ident' && keyToken.type != 'str') {
          throw NixParseException('expected attribute name');
        }
        position++;
        _expect('=');
        result[keyToken.value] = parseValue();
        _expect(';');
      }
      position++;
      return result;
    }
    throw NixParseException('unexpected token ${token.value}');
  }

  void _expect(String value) {
    final token = tokens[position];
    if (token.type != value) {
      throw NixParseException('expected $value');
    }
    position++;
  }
}

List<_Token> _tokenize(String text) {
  final tokens = <_Token>[];
  var index = 0;
  while (index < text.length) {
    final char = text[index];
    if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
      index++;
    } else if (char == '#') {
      while (index < text.length && text[index] != '\n') {
        index++;
      }
    } else if (char == '/' &&
        index + 1 < text.length &&
        text[index + 1] == '*') {
      final end = text.indexOf('*/', index + 2);
      if (end == -1) throw NixParseException('block comment not closed');
      index = end + 2;
    } else if ('{}[]=;'.contains(char)) {
      tokens.add(_Token(char, char));
      index++;
    } else if (char == '"') {
      final buffer = StringBuffer();
      var cursor = index + 1;
      var closed = false;
      while (cursor < text.length) {
        final current = text[cursor];
        if (current == '\\' && cursor + 1 < text.length) {
          final escaped = text[cursor + 1];
          if (escaped == 'n') {
            buffer.write('\n');
          } else if (escaped == 't') {
            buffer.write('\t');
          } else {
            buffer.write(escaped);
          }
          cursor += 2;
        } else if (current == '"') {
          closed = true;
          break;
        } else {
          buffer.write(current);
          cursor++;
        }
      }
      if (!closed) throw NixParseException('string not closed');
      tokens.add(_Token('str', buffer.toString()));
      index = cursor + 1;
    } else if (RegExp(r'[A-Za-z_]').hasMatch(char)) {
      final start = index;
      index++;
      while (index < text.length &&
          RegExp(r'[A-Za-z0-9_-]').hasMatch(text[index])) {
        index++;
      }
      tokens.add(_Token('ident', text.substring(start, index)));
    } else {
      throw NixParseException('unexpected character $char');
    }
  }
  tokens.add(_Token('eof', ''));
  return tokens;
}

dynamic parseNix(String text) {
  final parser = _Parser(_tokenize(text));
  final value = parser.parseValue();
  if (parser.tokens[parser.position].type != 'eof') {
    throw NixParseException('trailing tokens');
  }
  return value;
}

String _nixString(String value) {
  var text = value.replaceAll('\\', '\\\\');
  text = text.replaceAll('"', '\\"');
  text = text.replaceAll('\${', '\\${');
  text = text.replaceAll('\n', '\\n');
  return '"$text"';
}

String toNix(dynamic value, int indent) {
  final pad = '  ' * indent;
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is String) return _nixString(value);
  if (value is List) {
    if (value.isEmpty) return '[ ]';
    final items = value.map((item) => toNix(item, indent + 1)).join(' ');
    return '[ $items ]';
  }
  if (value is Map) {
    if (value.isEmpty) return '{ }';
    final lines = value.entries.map((entry) {
      final rawKey = entry.key.toString();
      final key = RegExp(r'^[A-Za-z_][A-Za-z0-9_-]*$').hasMatch(rawKey)
          ? rawKey
          : _nixString(rawKey);
      return '$pad  $key = ${toNix(entry.value, indent + 1)};';
    }).toList();
    return '{\n${lines.join('\n')}\n$pad}';
  }
  throw NixParseException('cannot serialize ${value.runtimeType}');
}

class OmnixyStore {
  final String root;
  OmnixyStore(this.root);

  String get configPath => '$root${Platform.pathSeparator}config${Platform.pathSeparator}omnixy.nix';
  String get modulesDir => '$root${Platform.pathSeparator}modules';

  Map<String, dynamic> defaults() => {
        'system': {
          'hostname': 'omnixy',
          'timezone': 'Asia/Shanghai',
          'locale': 'en_US.UTF-8',
          'networkManager': true,
        },
        'user': {
          'name': 'onekki',
          'fullName': 'Onekki',
          'hashedPassword': null,
          'extraGroups': <String>[],
        },
        'enabledModules': <String>['core', 'denial', 'rime'],
        'settings': <String, dynamic>{},
      };

  Future<Map<String, dynamic>> readConfig() async {
    final file = File(configPath);
    if (!await file.exists()) return defaults();
    final parsed = parseNix(await file.readAsString());
    return _normalize(parsed as Map<String, dynamic>);
  }

  Future<void> writeConfig(Map<String, dynamic> config) async {
    final file = File(configPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('${toNix(config, 0)}\n');
  }

  Future<List<ModuleSpec>> discoverModules() async {
    final directory = Directory(modulesDir);
    final specs = <ModuleSpec>[];
    if (!await directory.exists()) return specs;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.meta.nix')) continue;
      final id = name.substring(0, name.length - '.meta.nix'.length);
      final parsed = parseNix(await entity.readAsString()) as Map<String, dynamic>;
      specs.add(ModuleSpec(
        id: id,
        name: parsed['name'] as String? ?? id,
        description: parsed['description'] as String? ?? '',
        builtin: parsed['builtin'] as bool? ?? false,
        settings: (parsed['settings'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      ));
    }
    specs.sort((a, b) => a.id.compareTo(b.id));
    return specs;
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final system = Map<String, dynamic>.from(
        raw['system'] is Map ? raw['system'] as Map : const {});
    final user = Map<String, dynamic>.from(
        raw['user'] is Map ? raw['user'] as Map : const {});
    final defaults = this.defaults();
    final settings = Map<String, dynamic>.from(
        raw['settings'] is Map ? raw['settings'] as Map : const {});

    return {
      'system': {
        'hostname': system['hostname'] as String? ?? defaults['system']['hostname'],
        'timezone': system['timezone'] as String? ?? defaults['system']['timezone'],
        'locale': system['locale'] as String? ?? defaults['system']['locale'],
        'networkManager':
            system['networkManager'] as bool? ?? defaults['system']['networkManager'],
      },
      'user': {
        'name': user['name'] as String? ?? defaults['user']['name'],
        'fullName': user['fullName'] as String? ?? defaults['user']['fullName'],
        'hashedPassword': user['hashedPassword'],
        'extraGroups': (user['extraGroups'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
      },
      'enabledModules': (raw['enabledModules'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      'settings': settings,
    };
  }
}
