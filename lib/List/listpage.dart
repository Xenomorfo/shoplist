import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Shopping/listitemspreviewpage.dart';
import '../UI/app_widgets.dart';
import 'list.dart';
import 'list_repository.dart';

class ListyPage extends StatefulWidget {
  const ListyPage({super.key, required this.title});

  final String title;

  @override
  State<ListyPage> createState() => _ListyPageState();
}

class _ListyPageState extends State<ListyPage> {
  final _searchController = TextEditingController();
  List<Listy> _lists = [];
  bool _loading = true;
  String _query = '';

  List<Listy> get _filteredLists {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _lists;
    return _lists.where((l) => l.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLists() async {
    final lists = await listyRepoService.fetchLists();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  Future<void> _deleteList(Listy list) async {
    if (list.id == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Apagar lista?',
      message: list.isPredefined
          ? 'A lista predefinida “${list.name}” será removida. Os itens do catálogo não serão apagados.'
          : 'A lista “${list.name}” e as seleções de compra associadas serão removidas.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;

    await listyRepoService.deleteList(list.id!);
    await _fetchLists();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista apagada.')),
    );
  }

  Future<void> _showListDialog({Listy? list}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: list?.name ?? '');
    final isEditing = list != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(isEditing ? Icons.edit_note_rounded : Icons.playlist_add_rounded),
        title: Text(isEditing ? 'Editar lista' : 'Nova lista'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                prefixIcon: Icon(Icons.list_alt_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Indique um nome com pelo menos 2 caracteres.';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final now = DateTime.now();
              if (isEditing) {
                await listyRepoService.updateList(
                  Listy(
                    id: list.id,
                    name: nameController.text.trim(),
                    createdAt: list.createdAt ?? now,
                    updatedAt: now,
                    isPredefined: list.isPredefined,
                  ),
                );
              } else {
                await listyRepoService.addList(
                  Listy(
                    name: nameController.text.trim(),
                    createdAt: now,
                    updatedAt: now,
                    isPredefined: false,
                  ),
                );
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: Text(isEditing ? 'Guardar' : 'Criar'),
          ),
        ],
      ),
    );

    nameController.dispose();
    await _fetchLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova lista'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'As suas listas',
                    subtitle: '${_lists.length} ${_lists.length == 1 ? 'lista disponível' : 'listas disponíveis'}',
                  ),
                  const SizedBox(height: 14),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar listas...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredLists.isEmpty
                        ? EmptyState(
                            icon: Icons.playlist_add_rounded,
                            title: _query.isEmpty ? 'Ainda não existem listas' : 'Nenhuma lista encontrada',
                            message: _query.isEmpty
                                ? 'Crie uma lista pessoal ou utilize um dos modelos predefinidos.'
                                : 'Tente pesquisar por outro nome.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchLists,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredLists.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) => _listCard(_filteredLists[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _listCard(Listy list) {
    final scheme = Theme.of(context).colorScheme;
    final created = list.createdAt;
    final updated = list.updatedAt;

    return SurfaceCard(
      onTap: list.id == null
          ? null
          : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ListItemsPreviewPage(listId: list.id!)),
              );
              await _fetchLists();
            },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: list.isPredefined ? scheme.secondaryContainer : scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              list.isPredefined ? Icons.auto_awesome_rounded : Icons.list_alt_rounded,
              color: list.isPredefined ? scheme.onSecondaryContainer : scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (list.isPredefined) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Predefinida',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Criada ${created == null ? '—' : DateFormat('dd/MM/yyyy').format(created)}  ·  '
                  'Atualizada ${updated == null ? '—' : DateFormat('dd/MM/yyyy').format(updated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'edit') _showListDialog(list: list);
              if (value == 'delete') _deleteList(list);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Editar'))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Apagar'))),
            ],
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
