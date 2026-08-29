import 'package:flutter/material.dart';

import '../Category/category.dart';
import '../Category/category_repository.dart';
import '../Item/item.dart';
import '../Item/item_repository.dart';
import '../List/list.dart';
import '../List/list_repository.dart';
import '../UI/app_widgets.dart';
import '../UI/category_visuals.dart';
import '../Unity/unity.dart';
import '../Unity/unity_repository.dart';
import 'list_item.dart';
import 'listitems_repository.dart';
import 'listitemsselectedpage.dart';

class ListItemsChoosePage extends StatefulWidget {
  const ListItemsChoosePage({super.key});

  @override
  State<ListItemsChoosePage> createState() => _ListItemsChoosePageState();
}

class _ListItemsChoosePageState extends State<ListItemsChoosePage> {
  final _searchController = TextEditingController();
  int? _selectedListId;
  List<Listy> _lists = [];
  List<Category> _categories = [];
  List<Item> _items = [];
  List<Unity> _unities = [];
  final Set<int> _selectedItemIds = {};
  bool _loading = true;
  bool _saving = false;
  String _query = '';

  Map<int, Unity> get _unitiesById => {
        for (final u in _unities)
          if (u.id != null) u.id!: u,
      };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      listyRepoService.fetchLists(),
      categoryRepoService.fetchCategories(),
      itemRepoService.fetchItens(),
      unityRepoService.fetchUnities(),
    ]);
    if (!mounted) return;
    final lists = results[0] as List<Listy>;
    setState(() {
      _lists = lists;
      _categories = results[1] as List<Category>;
      _items = results[2] as List<Item>;
      _unities = results[3] as List<Unity>;
      _selectedListId ??= lists.where((l) => !l.isPredefined && l.id != null).firstOrNull?.id ??
          lists.where((l) => l.id != null).firstOrNull?.id;
      _loading = false;
    });
  }

  List<Item> _itemsForCategory(Category category) {
    final q = _query.trim().toLowerCase();
    return _items.where((item) {
      final categoryMatch = item.categoryId == category.id;
      final textMatch = q.isEmpty || (item.name ?? '').toLowerCase().contains(q);
      return categoryMatch && textMatch;
    }).toList();
  }

  List<Category> get _visibleCategories =>
      _categories.where((category) => _itemsForCategory(category).isNotEmpty).toList();

  Future<void> _saveSelectedItems() async {
    if (_selectedListId == null || _selectedItemIds.isEmpty || _saving) return;
    setState(() => _saving = true);

    var added = 0;
    for (final item in _items.where((i) => i.id != null && _selectedItemIds.contains(i.id))) {
      final inserted = await listItemRepoService.addListItemIfMissing(
        ListItem(
          listId: _selectedListId,
          itemId: item.id,
          qty: item.qty,
          notes: item.notes,
          isChecked: false,
        ),
      );
      if (inserted) added++;
    }

    if (!mounted) return;
    final duplicates = _selectedItemIds.length - added;
    setState(() {
      _saving = false;
      _selectedItemIds.clear();
    });

    final message = duplicates > 0
        ? '$added itens adicionados. $duplicates já estavam nesta lista.'
        : '$added ${added == 1 ? 'item adicionado' : 'itens adicionados'} às compras.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ListItemsSelectedPage(title: 'As Minhas Compras'),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar compras')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'Monte a sua lista',
                    subtitle: 'Escolha a lista de destino e selecione os produtos por categoria.',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: _selectedListId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lista de destino',
                      prefixIcon: Icon(Icons.list_alt_rounded),
                    ),
                    items: _lists
                        .where((list) => list.id != null)
                        .map(
                          (list) => DropdownMenuItem(
                            value: list.id!,
                            child: Text(list.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedListId = value),
                  ),
                  const SizedBox(height: 12),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar produtos...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedItemIds.length} ${_selectedItemIds.length == 1 ? 'item selecionado' : 'itens selecionados'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectedItemIds.isEmpty
                            ? null
                            : () => setState(() => _selectedItemIds.clear()),
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Limpar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _items.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Não há itens no catálogo',
                            message: 'Adicione primeiro alguns produtos na área de Itens.',
                          )
                        : _visibleCategories.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Nenhum produto encontrado',
                                message: 'Tente pesquisar por outro nome.',
                              )
                            : ListView.separated(
                                itemCount: _visibleCategories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) => _categorySection(_visibleCategories[index]),
                              ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedListId == null || _selectedItemIds.isEmpty || _saving
                          ? null
                          : _saveSelectedItems,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(
                        _selectedItemIds.isEmpty
                            ? 'Selecione os itens'
                            : 'Adicionar ${_selectedItemIds.length} às compras',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _categorySection(Category category) {
    final items = _itemsForCategory(category);
    if (items.isEmpty) return const SizedBox.shrink();
    final color = categoryColor(context, category.name);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: ValueKey('${category.id}-${_query.isNotEmpty}'),
        initiallyExpanded: _query.isNotEmpty,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(categoryIcon(category.name), color: color, size: 21),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${items.length} ${items.length == 1 ? 'item' : 'itens'}'),
        children: items.map(_itemTile).toList(),
      ),
    );
  }

  Widget _itemTile(Item item) {
    final id = item.id;
    final selected = id != null && _selectedItemIds.contains(id);
    final unity = item.unityId == null ? null : _unitiesById[item.unityId!];

    return CheckboxListTile(
      value: selected,
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(item.name ?? 'Item sem nome'),
      subtitle: Text('${formatQuantity(item.qty)} ${unity?.acronym ?? ''}${(item.notes ?? '').isEmpty ? '' : '  ·  ${item.notes}'}'),
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
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
