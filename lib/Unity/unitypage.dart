import 'package:flutter/material.dart';

import '../UI/app_widgets.dart';
import 'unity.dart';
import 'unity_repository.dart';

class UnityPage extends StatefulWidget {
  const UnityPage({super.key, required this.title});

  final String title;

  @override
  State<UnityPage> createState() => _UnityPageState();
}

class _UnityPageState extends State<UnityPage> {
  final _searchController = TextEditingController();
  List<Unity> _unities = [];
  bool _loading = true;
  String _query = '';

  List<Unity> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _unities;
    return _unities.where((u) => '${u.name} ${u.acronym} ${u.type}'.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchUnities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnities() async {
    final unities = await unityRepoService.fetchUnities();
    if (!mounted) return;
    setState(() {
      _unities = unities;
      _loading = false;
    });
  }

  Future<void> _deleteUnity(Unity unity) async {
    if (unity.id == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Apagar unidade?',
      message: 'A unidade “${unity.name}” só pode ser apagada quando não estiver em utilização.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await unityRepoService.deleteUnity(unity.id!);
      await _fetchUnities();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message.toString())));
    }
  }

  Future<void> _showUnityDialog({Unity? unity}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: unity?.name ?? '');
    final acronymController = TextEditingController(text: unity?.acronym ?? '');
    var type = unity?.type ?? 'Unidade';
    const types = ['Unidade', 'SubUnidade'];
    if (!types.contains(type)) type = 'Unidade';
    final isEditing = unity != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          icon: const Icon(Icons.straighten_rounded),
          title: Text(isEditing ? 'Editar unidade' : 'Nova unidade'),
          content: SizedBox(
            width: 430,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.straighten_rounded)),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Indique um nome.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: acronymController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Abreviatura', prefixIcon: Icon(Icons.short_text_rounded)),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Indique uma abreviatura.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo', prefixIcon: Icon(Icons.account_tree_rounded)),
                    items: types.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final updated = Unity(
                  id: unity?.id,
                  name: nameController.text.trim(),
                  acronym: acronymController.text.trim(),
                  type: type,
                );
                if (isEditing) {
                  await unityRepoService.updateUnity(updated);
                } else {
                  await unityRepoService.addUnity(updated);
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(isEditing ? 'Guardar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    acronymController.dispose();
    await _fetchUnities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUnityDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova unidade'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('Unidades de medida', subtitle: '${_unities.length} unidades configuradas'),
                  const SizedBox(height: 14),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar unidades...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.straighten_rounded,
                            title: 'Sem unidades',
                            message: 'Crie unidades para indicar quantidades de forma consistente.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchUnities,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) => _unityCard(_filtered[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _unityCard(Unity unity) {
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              unity.acronym,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unity.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(unity.type, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(tooltip: 'Editar', onPressed: () => _showUnityDialog(unity: unity), icon: const Icon(Icons.edit_rounded)),
          IconButton(
            tooltip: 'Apagar',
            onPressed: () => _deleteUnity(unity),
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
          ),
        ],
      ),
    );
  }
}
