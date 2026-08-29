import 'package:flutter/material.dart';

import '../History_Items/historyitem.dart';
import '../History_Items/historyitem_repository.dart';
import '../Item/item.dart';
import '../Item/item_repository.dart';
import '../List/list.dart';
import '../List/list_repository.dart';
import '../Shopping/list_item.dart';
import '../Shopping/listitems_repository.dart';
import '../UI/app_widgets.dart';
import '../Unity/unity.dart';
import '../Unity/unity_repository.dart';
import 'historylist.dart';
import 'historylist_repository.dart';

class HistoryListDetailsPage extends StatefulWidget {
  final int listId;

  const HistoryListDetailsPage({super.key, required this.listId});

  @override
  State<HistoryListDetailsPage> createState() => _HistoryListDetailsPageState();
}

class _HistoryListDetailsPageState extends State<HistoryListDetailsPage> {
  HistoryList? _list;
  List<HistoryItem> _items = [];
  List<Listy> _destinationLists = [];
  List<Item> _catalog = [];
  List<Unity> _units = [];
  final Set<int> _selectedItemIds = {};
  int? _selectedListId;
  bool _loading = true;
  bool _copying = false;

  Map<int, Unity> get _unitsById => {
        for (final unit in _units)
          if (unit.id != null) unit.id!: unit,
      };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      historyListRepoService.fetchOneHistoryList(widget.listId),
      historyItemRepoService.fetchHistoryItens(),
      listyRepoService.fetchLists(),
      itemRepoService.fetchItens(),
      unityRepoService.fetchUnities(),
    ]);

    if (!mounted) return;
    final list = results[0] as HistoryList?;
    final allHistoryItems = results[1] as List<HistoryItem>;
    final lists = results[2] as List<Listy>;

    setState(() {
      _list = list;
      _items = allHistoryItems.where((item) => item.listHistoryId == widget.listId).toList();
      _destinationLists = lists;
      _catalog = results[3] as List<Item>;
      _units = results[4] as List<Unity>;
      final preferred = lists.where((l) => !l.isPredefined && l.id != null).toList();
      _selectedListId = preferred.isNotEmpty ? preferred.first.id : lists.where((l) => l.id != null).firstOrNull?.id;
      _loading = false;
    });
  }

  Future<int?> _resolveCatalogItem(HistoryItem historyItem) async {
    final normalized = (historyItem.name ?? '').trim().toLowerCase();
    for (final item in _catalog) {
      if ((item.name ?? '').trim().toLowerCase() == normalized && item.id != null) {
        return item.id;
      }
    }

    final now = DateTime.now();
    final newId = await itemRepoService.addItem(
      Item(
        name: historyItem.name ?? 'Item recuperado',
        qty: historyItem.qty ?? 1,
        unityId: historyItem.unityId,
        categoryId: historyItem.categoryId,
        isBought: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _catalog.add(
      Item(
        id: newId,
        name: historyItem.name ?? 'Item recuperado',
        qty: historyItem.qty ?? 1,
        unityId: historyItem.unityId,
        categoryId: historyItem.categoryId,
        isBought: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return newId;
  }

  Future<void> _copySelectedItems() async {
    if (_selectedListId == null || _selectedItemIds.isEmpty || _copying) return;
    setState(() => _copying = true);

    var added = 0;
    for (final historyItem in _items.where((i) => i.id != null && _selectedItemIds.contains(i.id))) {
      final itemId = await _resolveCatalogItem(historyItem);
      if (itemId == null) continue;
      final inserted = await listItemRepoService.addListItemIfMissing(
        ListItem(
          listId: _selectedListId,
          itemId: itemId,
          qty: historyItem.qty,
          isChecked: false,
        ),
      );
      if (inserted) added++;
    }

    if (!mounted) return;
    setState(() {
      _copying = false;
      _selectedItemIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added ${added == 1 ? 'item copiado' : 'itens copiados'} para as compras atuais.')),
    );
  }

  void _toggleAll() {
    final ids = _items.map((i) => i.id).whereType<int>().toSet();
    final allSelected = ids.isNotEmpty && ids.every(_selectedItemIds.contains);
    setState(() {
      if (allSelected) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _list?.totalItems ?? _items.length;
    final bought = _list?.totalBought ?? _items.where((i) => i.wasBought).length;
    final progress = total <= 0 ? 0.0 : (bought / total).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(_list?.name ?? 'Detalhes do histórico')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list == null
              ? const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Histórico não encontrado',
                  message: 'Este registo poderá ter sido removido.',
                )
              : PageContainer(
                  maxWidth: 860,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summary(progress, bought, total),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SectionTitle(
                              'Itens comprados',
                              subtitle: '${_items.length} ${_items.length == 1 ? 'item registado' : 'itens registados'}',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _items.isEmpty ? null : _toggleAll,
                            icon: const Icon(Icons.select_all_rounded),
                            label: const Text('Selecionar todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _items.isEmpty
                            ? const EmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'Sem itens registados',
                                message: 'Não existem detalhes associados a esta lista.',
                              )
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) => _historyItemTile(_items[index]),
                              ),
                      ),
                      if (_items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedListId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Copiar selecionados para',
                            prefixIcon: Icon(Icons.copy_all_rounded),
                          ),
                          items: _destinationLists
                              .where((l) => l.id != null)
                              .map((l) => DropdownMenuItem(value: l.id!, child: Text(l.name)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedListId = value),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _selectedListId == null || _selectedItemIds.isEmpty || _copying
                                ? null
                                : _copySelectedItems,
                            icon: _copying
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.replay_rounded),
                            label: Text(
                              _selectedItemIds.isEmpty
                                  ? 'Selecione os itens a reutilizar'
                                  : 'Reutilizar ${_selectedItemIds.length} ${_selectedItemIds.length == 1 ? 'item' : 'itens'}',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _summary(double progress, int bought, int total) {
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      color: scheme.tertiaryContainer.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.receipt_long_rounded, color: scheme.onTertiary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumo da compra', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('$bought de $total itens foram comprados'),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
        ],
      ),
    );
  }

  Widget _historyItemTile(HistoryItem item) {
    final id = item.id;
    final selected = id != null && _selectedItemIds.contains(id);
    final unit = item.unityId == null ? null : _unitsById[item.unityId!];
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: selected,
        onChanged: id == null
            ? null
            : (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedItemIds.add(id);
                  } else {
                    _selectedItemIds.remove(id);
                  }
                });
              },
        title: Text(item.name ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${formatQuantity(item.qty)} ${unit?.acronym ?? ''}'),
        secondary: Icon(
          item.wasBought ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
          color: item.wasBought ? scheme.tertiary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
