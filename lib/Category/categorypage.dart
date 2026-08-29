import 'package:flutter/material.dart';

import '../UI/app_widgets.dart';
import '../UI/category_visuals.dart';
import 'category.dart';
import 'category_repository.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.title});

  final String title;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  bool _loading = true;
  String _query = '';

  List<Category> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final categories = await categoryRepoService.fetchCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.id == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Apagar categoria?',
      message: 'A categoria “${category.name}” só pode ser apagada se não estiver associada a itens.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await categoryRepoService.deleteCategory(category.id!);
      await _fetchCategories();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.toString())),
      );
    }
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    var isActive = category?.isActive ?? true;
    final isEditing = category != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          icon: Icon(isEditing ? Icons.edit_rounded : Icons.category_rounded),
          title: Text(isEditing ? 'Editar categoria' : 'Nova categoria'),
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
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    validator: (value) => value == null || value.trim().length < 2
                        ? 'Indique um nome válido.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text('Categoria ativa'),
                    subtitle: const Text('Categorias inativas deixam de aparecer na criação de novos itens.'),
                    value: isActive,
                    onChanged: (value) => setDialogState(() => isActive = value),
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
                final updated = Category(
                  id: category?.id,
                  name: nameController.text.trim(),
                  icon: category?.icon,
                  color: category?.color,
                  isActive: isActive,
                );
                if (isEditing) {
                  await categoryRepoService.updateCategory(updated);
                } else {
                  await categoryRepoService.addCategory(updated);
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
    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _categories.where((c) => c.isActive).length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova categoria'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Categorias',
                    subtitle: '$activeCount ativas · ${_categories.length - activeCount} inativas',
                  ),
                  const SizedBox(height: 14),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar categorias...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.category_outlined,
                            title: 'Sem categorias',
                            message: 'Crie categorias para manter o catálogo organizado.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchCategories,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) => _categoryCard(_filtered[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _categoryCard(Category category) {
    final scheme = Theme.of(context).colorScheme;
    final color = categoryColor(context, category.name);
    return Opacity(
      opacity: category.isActive ? 1 : 0.62,
      child: SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(categoryIcon(category.name), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    category.isActive ? 'Disponível para novos itens' : 'Categoria inativa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _showCategoryDialog(category: category),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Apagar',
              onPressed: () => _deleteCategory(category),
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          ],
        ),
      ),
    );
  }
}
