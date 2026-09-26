import 'package:flutter/material.dart';

import 'src/nix_helper.dart';
import 'src/omnixy_store.dart';

class OmnixyDashboardScene extends StatefulWidget {
  final String repoRoot;
  const OmnixyDashboardScene({super.key, required this.repoRoot});

  @override
  State<OmnixyDashboardScene> createState() => _OmnixyDashboardSceneState();
}

class _OmnixyDashboardSceneState extends State<OmnixyDashboardScene> {
  late final OmnixyStore _store;
  final _hostname = TextEditingController();
  final _timezone = TextEditingController();
  final _locale = TextEditingController();
  final _userName = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  final _groups = TextEditingController();
  final _searchQuery = TextEditingController();
  final _moduleFilter = TextEditingController();
  final _flakeQuery = TextEditingController();

  Map<String, dynamic>? _config;
  List<ModuleSpec> _modules = [];
  Map<String, bool> _enabled = {};
  Map<String, Map<String, dynamic>> _moduleValues = {};
  List<PackageHit> _searchResults = [];
  List<Map<String, String>> _flakeResults = [];
  bool _loading = true;
  bool _working = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _store = OmnixyStore(widget.repoRoot);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = '加载中...';
    });
    try {
      final config = await _store.readConfig();
      final modules = await _store.discoverModules();
      final enabled = <String, bool>{
        for (final id in (config['enabledModules'] as List<dynamic>).cast<String>())
          id: true,
      };
      final values = <String, Map<String, dynamic>>{};
      for (final module in modules) {
        values[module.id] = Map<String, dynamic>.from(
          (config['settings'] as Map<String, dynamic>)[module.id] is Map
              ? (config['settings'] as Map<String, dynamic>)[module.id] as Map
              : const {},
        );
      }
      setState(() {
        _config = config;
        _modules = modules;
        _enabled = enabled;
        _moduleValues = values;
        _hostname.text = (config['system'] as Map<String, dynamic>)['hostname'] as String? ?? '';
        _timezone.text = (config['system'] as Map<String, dynamic>)['timezone'] as String? ?? '';
        _locale.text = (config['system'] as Map<String, dynamic>)['locale'] as String? ?? '';
        _userName.text = (config['user'] as Map<String, dynamic>)['name'] as String? ?? '';
        _fullName.text = (config['user'] as Map<String, dynamic>)['fullName'] as String? ?? '';
        _password.text =
            ((config['user'] as Map<String, dynamic>)['hashedPassword'] as String?) ?? '';
        _groups.text = ((config['user'] as Map<String, dynamic>)['extraGroups'] as List<dynamic>)
            .join(', ');
        _status = '已载入';
      });
    } catch (error) {
      setState(() => _status = '加载失败：$error');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _collect() {
    final settings = <String, dynamic>{};
    for (final module in _modules) {
      if ((_moduleValues[module.id] ?? {}).isNotEmpty) {
        settings[module.id] = _moduleValues[module.id];
      }
    }
    return {
      if (_config != null) ..._config!,
      'system': {
        'hostname': _hostname.text.trim(),
        'timezone': _timezone.text.trim(),
        'locale': _locale.text.trim(),
        'networkManager':
            (_config?['system'] as Map<String, dynamic>?)?.containsKey('networkManager') == true
                ? (_config!['system'] as Map<String, dynamic>)['networkManager']
                : true,
      },
      'user': {
        'name': _userName.text.trim(),
        'fullName': _fullName.text.trim(),
        'hashedPassword': _password.text.trim().isEmpty ? null : _password.text.trim(),
        'extraGroups': _groups.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      },
      'enabledModules': _modules
          .where((module) => _enabled[module.id] ?? false)
          .map((module) => module.id)
          .toList(),
      'settings': settings,
    };
  }

  Future<void> _save() async {
    setState(() {
      _working = true;
      _status = '保存中...';
    });
    try {
      final config = _collect();
      await _store.writeConfig(config);
      setState(() {
        _config = config;
        _status = '已保存';
      });
    } catch (error) {
      setState(() => _status = '保存失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  Future<void> _search() async {
    final query = _searchQuery.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _working = true;
      _status = '搜索 nixpkgs...';
    });
    try {
      final hits = await searchNixpkgs(query);
      setState(() {
        _searchResults = hits;
        _status = '找到 ${hits.length} 个软件包';
      });
    } catch (error) {
      setState(() => _status = '搜索失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  Future<void> _createPackageModule(PackageHit hit) async {
    setState(() {
      _working = true;
      _status = '创建软件包模块...';
    });
    try {
      await _store.createPackageModule(hit.attr);
      await _load();
      setState(() => _status = '模块 ${hit.attr} 已创建并启用');
    } catch (error) {
      setState(() => _status = '创建失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  Future<void> _searchFlakes() async {
    final query = _flakeQuery.text.trim();
    if (query.isEmpty) return;

    if (query.contains('github:') ||
        query.contains('git+') ||
        query.contains('://')) {
      final name = _deriveFlakeName(query);
      await _createFlakeModule(
        name: name,
        url: query,
        description: name,
      );
      return;
    }

    setState(() {
      _working = true;
      _status = '搜索 flake 注册表...';
    });
    try {
      final results = await searchFlakes(query);
      setState(() {
        _flakeResults = results;
        _status = '找到 ${results.length} 个 flake';
      });
    } catch (error) {
      setState(() => _status = '搜索失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  Future<void> _createFlakeModule({
    required String name,
    required String url,
    required String description,
  }) async {
    setState(() {
      _working = true;
      _status = '创建 flake 模块...';
    });
    try {
      await _store.createFlakeModule(
        flakeInput: name,
        url: url,
        description: description,
      );
      await _load();
      setState(() => _status = 'flake 模块 $name 已创建并启用');
    } catch (error) {
      setState(() => _status = '创建失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  String _deriveFlakeName(String url) {
    final base = url.split('?').first.split('#').first;
    final last = base.split('/').last.split(':').last;
    var name = last
        .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
        .toLowerCase()
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (name.isEmpty) name = 'flake';
    if (RegExp(r'^[0-9]').hasMatch(name)) name = 'f$name';
    return name;
  }

  Future<void> _deleteModule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模块'),
        content: Text('确定删除模块 $id？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _working = true;
      _status = '删除中...';
    });
    try {
      await _store.deleteModule(id);
      await _load();
      setState(() => _status = '模块 $id 已删除');
    } catch (error) {
      setState(() => _status = '删除失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  Future<void> _rebuild() async {
    setState(() {
      _working = true;
      _status = '构建中...';
    });
    try {
      final output = await rebuild(widget.repoRoot);
      setState(() => _status = '构建完成：${output.split('\n').last}');
    } catch (error) {
      setState(() => _status = '构建失败：$error');
    } finally {
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: Colors.black.withValues(alpha: 0.82),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _section('系统', [
                      _textField(_hostname, '主机名'),
                      _textField(_timezone, '时区'),
                      _textField(_locale, '语言区域'),
                    ]),
                    _section('用户', [
                      _textField(_userName, '用户名'),
                      _textField(_fullName, '全名'),
                      _textField(_password, '密码哈希'),
                      _textField(_groups, '附加组（逗号分隔）'),
                    ]),
                    _section('模块', [
                      _textField(_moduleFilter, '搜索模块'),
                      for (final module in _modules.where(_moduleMatches))
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: Text(module.name),
                                subtitle: Text(module.description),
                                value: _enabled[module.id] ?? false,
                                onChanged: (value) => setState(
                                  () => _enabled[module.id] = value,
                                ),
                              ),
                            ),
                            if (!module.builtin)
                              IconButton(
                                tooltip: '删除模块',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _working
                                    ? null
                                    : () => _deleteModule(module.id),
                              ),
                          ],
                        ),
                    ]),
                    _section('Flake 模块搜索', [
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              _flakeQuery,
                              '搜索注册表或输入 flake URL',
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _working ? null : _searchFlakes,
                            child: const Text('搜索'),
                          ),
                        ],
                      ),
                      for (final flake in _flakeResults)
                        ListTile(
                          dense: true,
                          title: Text(flake['name'] ?? ''),
                          subtitle: Text(flake['url'] ?? ''),
                          trailing: IconButton(
                            tooltip: '创建模块',
                            icon: const Icon(Icons.add_box_outlined),
                            onPressed: _working
                                ? null
                                : () => _createFlakeModule(
                                      name: flake['name'] ?? '',
                                      url: flake['url'] ?? '',
                                      description: flake['name'] ?? '',
                                    ),
                          ),
                        ),
                    ]),
                    _section('nixpkgs 搜索', [
                      Row(
                        children: [
                          Expanded(
                            child: _textField(_searchQuery, '搜索软件包'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _working ? null : _search,
                            child: const Text('搜索'),
                          ),
                        ],
                      ),
                      for (final hit in _searchResults)
                        ListTile(
                          dense: true,
                          title: Text('${hit.name} ${hit.version}'),
                          subtitle: Text(hit.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(hit.attr),
                              IconButton(
                                tooltip: '创建模块',
                                icon: const Icon(Icons.add_box_outlined),
                                onPressed: _working
                                    ? null
                                    : () => _createPackageModule(hit),
                              ),
                            ],
                          ),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _working ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('保存配置'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _working ? null : _rebuild,
                          icon: const Icon(Icons.build_outlined),
                          label: const Text('构建系统'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  bool _moduleMatches(ModuleSpec module) {
    final query = _moduleFilter.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return module.id.toLowerCase().contains(query) ||
        module.name.toLowerCase().contains(query) ||
        module.description.toLowerCase().contains(query);
  }

  Widget _textField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlueAccent),
          ),
        ),
      ),
    );
  }
}
