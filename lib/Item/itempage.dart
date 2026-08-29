import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Category/category.dart';
import '../Category/category_repository.dart';
import '../UI/app_widgets.dart';
import '../UI/category_visuals.dart';
import '../Unity/unity.dart';
import '../Unity/unity_repository.dart';
import 'item.dart';
import 'item_repository.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key, required this.title});

  final String title;

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final _searchController = TextEditingController();
  List<Item> _items = [];
  List<Category> _categories = [];
  List<Unity> _unities = [];
  bool _loading = true;
  String _query = '';
  int? _filterCategoryId;

  Map<int, Category> get _categoriesById => {
        for (final category in _categories)
          if (category.id != null) category.id!: category,
      };

  Map<int, Unity> get _unitiesById => {
        for (final unity in _unities)
          if (unity.id != null) unity.id!: unity,
      };

  List<Item> get _filteredItems {
    final q = _query.trim().toLowerCase();
    return _items.where((item) {
      final matchesText = q.isEmpty || (item.name ?? '').toLowerCase().contains(q);
      final matchesCategory = _filterCategoryId == null || item.categoryId == _filterCategoryId;
      return matchesText && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    final results = await Future.wait([
      itemRepoService.fetchItens(),
      categoryRepoService.fetchCategories(),
      unityRepoService.fetchUnities(),
    ]);
    if (!mounted) return;
    setState(() {
      _items = results[0] as List<Item>;
      _categories = results[1] as List<Category>;
      _unities = results[2] as List<Unity>;
      _loading = false;
    });
  }

  Future<void> _deleteItem(Item item) async {
    if (item.id == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Apagar item?',
      message: '“${item.name ?? 'Item'}” será removido do catálogo e também de compras atuais onde esteja selecionado.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;
    await itemRepoService.deleteItem(item.id!);
    await _fetchItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item apagado.')));
  }

  Future<void> _showItemDialog({Item? item}) async {
    final availableUnities = _unities.where((u) => u.id != null).toList();
    final availableCategories = _categories
        .where((c) => c.id != null && (c.isActive || c.id == item?.categoryId))
        .toList();
    if (availableCategories.isEmpty || availableUnities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie primeiro pelo menos uma categoria ativa e uma unidade.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController = TextEditingController(
      text: item == null ? '1' : formatQuantity(item.qty),
    );
    final notesController = TextEditingController(text: item?.notes ?? '');
    int? selectedUnitId = availableUnities.any((u) => u.id == item?.unityId)
        ? item?.unityId
        : availableUnities.first.id;
    int? selectedCategoryId = availableCategories.any((c) => c.id == item?.categoryId)
        ? item?.categoryId
        : availableCategories.first.id;
    final isEditing = item != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: Icon(isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded),
          title: Text(isEditing ? 'Editar item' : 'Novo item'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      validator: (value) => value == null || value.trim().length < 2
                          ? 'Indique o nome do item.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        final qty = double.tryParse((value ?? '').replaceAll(',', '.'));
                        if (qty == null || qty <= 0) return 'Indique uma quantidade válida.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      items: _unities
                          .where((u) => u.id != null)
                          .map(
                            (u) => DropdownMenuItem(
                              value: u.id!,
                              child: Text('${u.name} (${u.acronym})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedUnitId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: _categories
                          .where((c) => c.id != null && (c.isActive || c.id == selectedCategoryId))
                          .map((c) => DropdownMenuItem(value: c.id!, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                if (selectedUnitId == null || selectedCategoryId == null) return;
                final now = DateTime.now();
                final updated = Item(
                  id: item?.id,
                  listId: item?.listId,
                  name: nameController.text.trim(),
                  qty: double.parse(quantityController.text.replaceAll(',', '.')),
                  unityId: selectedUnitId,
                  categoryId: selectedCategoryId,
                  isBought: item?.isBought ?? false,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  createdAt: item?.createdAt ?? now,
                  updatedAt: now,
                );
                if (isEditing) {
                  await itemRepoService.updateItem(updated);
                } else {
                  await itemRepoService.addItem(updated);
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
    quantityController.dispose();
    notesController.dispose();
    await _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Catálogo de itens',
                    subtitle: '${_items.length} ${_items.length == 1 ? 'item disponível' : 'itens disponíveis'}',
                  ),
                  const SizedBox(height: 14),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar no catálogo...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _filterCategoryId == null,
                            label: const Text('Todas'),
                            onSelected: (_) => setState(() => _filterCategoryId = null),
                          ),
                        ),
                        ..._categories.where((c) => c.id != null).map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  avatar: Icon(categoryIcon(category.name), size: 17),
                                  selected: _filterCategoryId == category.id,
                                  label: Text(category.name),
                                  onSelected: (_) => setState(() => _filterCategoryId = category.id),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: _items.isEmpty ? 'Catálogo vazio' : 'Nenhum item encontrado',
                            message: _items.isEmpty
                                ? 'Adicione produtos para os poder reutilizar nas suas listas.'
                                : 'Altere a pesquisa ou o filtro de categoria.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchItems,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) => _itemCard(_filteredItems[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _itemCard(Item item) {
    final category = item.categoryId == null ? null : _categoriesById[item.categoryId!];
    final unity = item.unityId == null ? null : _unitiesById[item.unityId!];
    final categoryName = category?.name ?? 'Sem categoria';
    final color = categoryColor(context, categoryName);
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(categoryIcon(categoryName), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? 'Item sem nome',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$categoryName  ·  ${formatQuantity(item.qty)} ${unity?.acronym ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if ((item.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _showItemDialog(item: item),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Apagar',
            onPressed: () => _deleteItem(item),
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
          ),
        ],
      ),
    );
  }
}
