import 'package:flutter/material.dart';

import '../History_List/historylist_repository.dart';
import '../Item/item.dart';
import '../Item/item_repository.dart';
import '../List/list.dart';
import '../List/list_repository.dart';
import '../UI/app_widgets.dart';
import '../Unity/unity.dart';
import '../Unity/unity_repository.dart';
import 'list_item.dart';
import 'listitems_repository.dart';
import 'listitemschoosepage.dart';

class ListItemsSelectedPage extends StatefulWidget {
  final String title;

  const ListItemsSelectedPage({super.key, required this.title});

  @override
  State<ListItemsSelectedPage> createState() => _ListItemsSelectedPageState();
}

class _ListItemsSelectedPageState extends State<ListItemsSelectedPage> {
  List<ListItem> _listItems = [];
  List<Item> _items = [];
  List<Unity> _units = [];
  List<Listy> _lists = [];
  bool _loading = true;
  int? _finishingListId;

  int get _remaining => _listItems.where((e) => !e.isChecked).length;
  int get _bought => _listItems.where((e) => e.isChecked).length;

  Map<int, Item> get _itemsById => {
        for (final item in _items)
          if (item.id != null) item.id!: item,
      };

  Map<int, Unity> get _unitsById => {
        for (final unit in _units)
          if (unit.id != null) unit.id!: unit,
      };

  Map<int, Listy> get _listsById => {
        for (final list in _lists)
          if (list.id != null) list.id!: list,
      };

  @override
  void initState() {
    super.initState();
    _fetchSelected();
  }

  Future<void> _fetchSelected() async {
    final results = await Future.wait([
      listItemRepoService.fetchListItens(),
      itemRepoService.fetchItens(),
      unityRepoService.fetchUnities(),
      listyRepoService.fetchLists(),
    ]);
    if (!mounted) return;
    setState(() {
      _listItems = results[0] as List<ListItem>;
      _items = results[1] as List<Item>;
      _units = results[2] as List<Unity>;
      _lists = results[3] as List<Listy>;
      _loading = false;
      _finishingListId = null;
    });
  }

  Future<void> _toggleItem(ListItem listItem) async {
    final oldValue = listItem.isChecked;
    setState(() => listItem.isChecked = !oldValue);
    try {
      await listItemRepoService.updateListItem(listItem);
    } catch (_) {
      if (!mounted) return;
      setState(() => listItem.isChecked = oldValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o item.')),
      );
    }
  }

  Future<void> _setAll(List<ListItem> items, bool checked) async {
    setState(() {
      for (final item in items) {
        item.isChecked = checked;
      }
    });
    await Future.wait(items.map(listItemRepoService.updateListItem));
  }

  Future<void> _removeCurrentItem(ListItem listItem) async {
    final item = _itemsById[listItem.itemId];
    final confirmed = await confirmAction(
      context,
      title: 'Remover das compras?',
      message: '“${item?.name ?? 'Item'}” será retirado desta lista de compras.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirmed) return;
    await listItemRepoService.deleteListItem(listItem.id);
    await _fetchSelected();
  }

  Future<void> _finishList(Listy list, List<ListItem> items) async {
    if (list.id == null || items.isEmpty || _finishingListId != null) return;
    final remaining = items.where((item) => !item.isChecked).length;
    final confirmed = await confirmAction(
      context,
      title: 'Concluir “${list.name}”?',
      message: remaining == 0
          ? 'Todos os itens estão marcados como comprados. A lista será movida para o histórico.'
          : 'Ainda existem $remaining ${remaining == 1 ? 'item pendente' : 'itens pendentes'}. Pode concluir na mesma; o histórico irá guardar o estado atual.',
      confirmLabel: 'Concluir lista',
    );
    if (!confirmed) return;

    setState(() => _finishingListId = list.id);

    try {
      await historyListRepoService.archiveShoppingList(
        sourceList: list,
        shoppingItems: items,
        catalogById: _itemsById,
      );
      await _fetchSelected();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista concluída e guardada no histórico.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishingListId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível concluir a lista.')),
      );
    }
  }

  Map<Listy, List<ListItem>> _groupItemsByList() {
    final grouped = <Listy, List<ListItem>>{};
    final listsById = _listsById;
    for (final item in _listItems) {
      final listId = item.listId;
      if (listId == null) continue;
      final list = listsById[listId];
      if (list == null) continue;
      grouped.putIfAbsent(list, () => <ListItem>[]).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final total = _listItems.length;
    final progress = total == 0 ? 0.0 : _bought / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Adicionar itens',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ListItemsChoosePage()),
              );
              await _fetchSelected();
            },
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: _listItems.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'A lista de compras está vazia',
                      message: 'Escolha produtos do catálogo ou abra uma lista predefinida para começar.',
                      action: FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ListItemsChoosePage()),
                          );
                          await _fetchSelected();
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Escolher produtos'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSelected,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _summaryCard(progress),
                          const SizedBox(height: 22),
                          SectionTitle(
                            'Listas em curso',
                            subtitle: '${_groupItemsByList().length} ${_groupItemsByList().length == 1 ? 'lista ativa' : 'listas ativas'}',
                          ),
                          const SizedBox(height: 12),
                          ..._groupItemsByList().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _listSection(entry.key, entry.value),
                                ),
                              ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _summaryCard(double progress) {
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      color: scheme.primaryContainer.withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.shopping_cart_checkout_rounded, color: scheme.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _remaining == 0 ? 'Compras completas!' : 'Faltam $_remaining ${_remaining == 1 ? 'item' : 'itens'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text('$_bought de ${_listItems.length} comprados'),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 9),
          ),
        ],
      ),
    );
  }

  Widget _listSection(Listy list, List<ListItem> items) {
    final checked = items.where((item) => item.isChecked).length;
    final progress = items.isEmpty ? 0.0 : checked / items.length;
    final isFinishing = _finishingListId == list.id;
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.list_alt_rounded, color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text('$checked de ${items.length} comprados'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'all') _setAll(items, true);
                    if (value == 'none') _setAll(items, false);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'all', child: Text('Marcar todos')), 
                    PopupMenuItem(value: 'none', child: Text('Desmarcar todos')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...items.map(_itemTile),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: isFinishing ? null : () => _finishList(list, items),
                icon: isFinishing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.task_alt_rounded),
                label: const Text('Concluir esta lista'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(ListItem listItem) {
    final item = _itemsById[listItem.itemId];
    final unit = item?.unityId == null ? null : _unitsById[item!.unityId!];
    final checked = listItem.isChecked;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: Checkbox(
        value: checked,
        onChanged: (_) => _toggleItem(listItem),
      ),
      title: Text(
        item?.name ?? 'Item desconhecido',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: checked ? TextDecoration.lineThrough : null,
          color: checked ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(
        '${formatQuantity(listItem.qty ?? item?.qty)} ${unit?.acronym ?? ''}'
        '${(listItem.notes ?? item?.notes ?? '').trim().isEmpty ? '' : '  ·  ${listItem.notes ?? item?.notes}'}',
      ),
      trailing: IconButton(
        tooltip: 'Remover',
        onPressed: () => _removeCurrentItem(listItem),
        icon: const Icon(Icons.close_rounded),
      ),
      onTap: () => _toggleItem(listItem),
    );
  }
}
