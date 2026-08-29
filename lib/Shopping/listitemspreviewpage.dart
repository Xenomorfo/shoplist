import 'package:flutter/material.dart';

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
import 'listitemsselectedpage.dart';

class ListItemsPreviewPage extends StatefulWidget {
  final int listId;
  final bool isPredefined;

  const ListItemsPreviewPage({
    super.key,
    required this.listId,
    this.isPredefined = false,
  });

  @override
  State<ListItemsPreviewPage> createState() => _ListItemsPreviewPageState();
}

class _ListItemsPreviewPageState extends State<ListItemsPreviewPage> {
  final _searchController = TextEditingController();
  Listy? _list;
  List<ListItem> _items = [];
  final Set<int> _selectedItemIds = {};
  final Map<int, Item> _itemsCatalog = {};
  final Map<int, Unity> _unities = {};
  bool _loading = true;
  bool _saving = false;
  String _query = '';

  bool get _isPredefined => _list?.isPredefined ?? widget.isPredefined;

  List<ListItem> get _filteredItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((li) {
      final name = _itemsCatalog[li.itemId]?.name ?? '';
      return name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await listyRepoService.fetchOneList(widget.listId);
    if (list == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final catalog = await itemRepoService.fetchItens();
    final units = await unityRepoService.fetchUnities();
    final items = list.isPredefined
        ? catalog
            .where((item) => item.listId == list.id && item.id != null)
            .map(
              (item) => ListItem(
                listId: list.id,
                itemId: item.id,
                qty: item.qty,
                notes: item.notes,
                isChecked: false,
              ),
            )
            .toList()
        : await listItemRepoService.fetchItemsByListId(widget.listId);

    if (!mounted) return;
    setState(() {
      _list = list;
      _items = items;
      _itemsCatalog
        ..clear()
        ..addEntries(catalog.where((i) => i.id != null).map((i) => MapEntry(i.id!, i)));
      _unities
        ..clear()
        ..addEntries(units.where((u) => u.id != null).map((u) => MapEntry(u.id!, u)));
      _loading = false;
    });
  }

  void _toggleSelection(ListItem item, bool selected) {
    final id = item.itemId;
    if (id == null) return;
    setState(() {
      if (selected) {
        _selectedItemIds.add(id);
      } else {
        _selectedItemIds.remove(id);
      }
    });
  }

  void _toggleAll() {
    final visibleIds = _filteredItems.map((i) => i.itemId).whereType<int>().toSet();
    final allSelected = visibleIds.isNotEmpty && visibleIds.every(_selectedItemIds.contains);
    setState(() {
      if (allSelected) {
        _selectedItemIds.removeAll(visibleIds);
      } else {
        _selectedItemIds.addAll(visibleIds);
      }
    });
  }

  Future<void> _addSelectedItemsToShopping() async {
    if (!_isPredefined || _selectedItemIds.isEmpty || _saving) return;
    setState(() => _saving = true);

    final selected = _items.where((i) => _selectedItemIds.contains(i.itemId)).map(
          (i) => ListItem(
            listId: widget.listId,
            itemId: i.itemId,
            qty: i.qty ?? _itemsCatalog[i.itemId]?.qty,
            notes: i.notes ?? _itemsCatalog[i.itemId]?.notes,
            isChecked: false,
          ),
        );

    final added = await listItemRepoService.addItemsToActiveList(selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);

    final skipped = _selectedItemIds.length - added;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skipped > 0
              ? '$added adicionados · $skipped já estavam nas compras.'
              : '$added ${added == 1 ? 'item adicionado' : 'itens adicionados'} às compras.',
        ),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ListItemsSelectedPage(title: 'As Minhas Compras'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_list?.name ?? 'Lista')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list == null
              ? const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Lista não encontrada',
                  message: 'Esta lista poderá ter sido removida.',
                )
              : PageContainer(
                  maxWidth: 860,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(
                        _isPredefined ? 'Modelo de compras' : 'Itens da lista',
                        subtitle: _isPredefined
                            ? 'Selecione os produtos que pretende adicionar às compras atuais.'
                            : 'Esta lista contém ${_items.length} ${_items.length == 1 ? 'item' : 'itens'} nas compras atuais.',
                      ),
                      const SizedBox(height: 14),
                      SearchBox(
                        controller: _searchController,
                        hintText: 'Pesquisar nesta lista...',
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      if (_isPredefined && _items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedItemIds.length} selecionados',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _toggleAll,
                              icon: const Icon(Icons.select_all_rounded),
                              label: const Text('Selecionar todos'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: _filteredItems.isEmpty
                            ? EmptyState(
                                icon: _items.isEmpty ? Icons.playlist_add_rounded : Icons.search_off_rounded,
                                title: _items.isEmpty ? 'Lista vazia' : 'Nenhum item encontrado',
                                message: _items.isEmpty
                                    ? (_isPredefined
                                        ? 'Este modelo ainda não tem itens associados.'
                                        : 'Adicione produtos através da Seleção de Compras.')
                                    : 'Tente pesquisar por outro nome.',
                                action: !_isPredefined && _items.isEmpty
                                    ? FilledButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const ListItemsChoosePage()),
                                        ),
                                        icon: const Icon(Icons.add_shopping_cart_rounded),
                                        label: const Text('Adicionar itens'),
                                      )
                                    : null,
                              )
                            : ListView.separated(
                                itemCount: _filteredItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) => _itemTile(_filteredItems[index]),
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _isPredefined
                            ? FilledButton.icon(
                                onPressed: _selectedItemIds.isEmpty || _saving ? null : _addSelectedItemsToShopping,
                                icon: _saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.add_shopping_cart_rounded),
                                label: Text(
                                  _selectedItemIds.isEmpty
                                      ? 'Selecione os itens'
                                      : 'Adicionar ${_selectedItemIds.length} às compras',
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ListItemsSelectedPage(title: 'As Minhas Compras'),
                                  ),
                                ),
                                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                                label: const Text('Abrir nas minhas compras'),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _itemTile(ListItem listItem) {
    final item = _itemsCatalog[listItem.itemId];
    final unity = item?.unityId == null ? null : _unities[item!.unityId!];
    final selected = listItem.itemId != null && _selectedItemIds.contains(listItem.itemId);
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.shopping_basket_outlined, color: scheme.onPrimaryContainer),
        ),
        title: Text(item?.name ?? 'Item desconhecido', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${formatQuantity(listItem.qty ?? item?.qty)} ${unity?.acronym ?? ''}'
          '${(listItem.notes ?? item?.notes ?? '').trim().isEmpty ? '' : '  ·  ${listItem.notes ?? item?.notes}'}',
        ),
        trailing: _isPredefined
            ? Checkbox(
                value: selected,
                onChanged: (value) => _toggleSelection(listItem, value ?? false),
              )
            : (listItem.isChecked
                ? Icon(Icons.check_circle_rounded, color: scheme.tertiary)
                : const Icon(Icons.radio_button_unchecked_rounded)),
        onTap: _isPredefined ? () => _toggleSelection(listItem, !selected) : null,
      ),
    );
  }
}
