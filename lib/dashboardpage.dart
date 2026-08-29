import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Category/category.dart';
import 'Category/category_repository.dart';
import 'Category/categorypage.dart';
import 'Configuration/configurationpage.dart';
import 'History_List/historylist_repository.dart';
import 'History_List/historylistpage.dart';
import 'Item/item.dart';
import 'Item/item_repository.dart';
import 'Item/itempage.dart';
import 'List/list.dart';
import 'List/list_repository.dart';
import 'List/listpage.dart';
import 'Shopping/listitems_repository.dart';
import 'Shopping/listitemschoosepage.dart';
import 'Shopping/listitemspreviewpage.dart';
import 'Shopping/listitemsselectedpage.dart';
import 'UI/app_widgets.dart';
import 'UI/category_visuals.dart';
import 'Unity/unitypage.dart';
import 'actionloggerservice.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.title});

  final String title;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _actionLogger = const ActionLoggerService();

  List<Listy> _recentLists = [];
  List<Listy> _predefinedLists = [];
  List<Category> _topCategories = [];
  List<Map<String, dynamic>> _recentActions = [];
  int _pendingItems = 0;
  int _historyLists = 0;
  int _activeLists = 0;
  int _catalogItems = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait<dynamic>([
        listyRepoService.fetchLists(),
        historyListRepoService.fetchHistoryList(),
        listItemRepoService.fetchListItens(),
        itemRepoService.fetchItens(),
        categoryRepoService.fetchCategories(),
        _actionLogger.getActions(),
      ]);

      final lists = results[0] as List<Listy>;
      final history = results[1] as List;
      final shoppingItems = results[2] as List;
      final items = results[3] as List<Item>;
      final categories = results[4] as List<Category>;
      final actions = results[5] as List<Map<String, dynamic>>;

      final nonPredefined = lists.where((l) => !l.isPredefined).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt ?? DateTime(2000);
          final bd = b.updatedAt ?? b.createdAt ?? DateTime(2000);
          return bd.compareTo(ad);
        });

      final categoryCounts = <int, int>{};
      for (final item in items) {
        final categoryId = item.categoryId;
        if (categoryId != null) {
          categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
        }
      }
      final sortedCategoryIds = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final categoryById = {for (final c in categories) c.id: c};
      final topCategories = sortedCategoryIds
          .take(4)
          .map((e) => categoryById[e.key])
          .whereType<Category>()
          .toList();

      final activeIds = shoppingItems
          .map((dynamic e) => e.listId as int?)
          .whereType<int>()
          .toSet();

      if (!mounted) return;
      setState(() {
        _recentLists = nonPredefined.take(3).toList();
        _predefinedLists = lists.where((l) => l.isPredefined).toList();
        _topCategories = topCategories;
        _recentActions = actions.take(5).toList();
        _pendingItems = shoppingItems.where((dynamic e) => e.isChecked == false).length;
        _historyLists = history.length;
        _activeLists = activeIds.length;
        _catalogItems = items.length;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível atualizar o dashboard.';
      });
    }
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _loadDashboardData();
  }

  Future<void> _openFromDrawer(Widget page) async {
    Navigator.of(context).pop();
    await _openPage(page);
  }

  Widget _menuDrawer() {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: SurfaceCard(
                color: scheme.primaryContainer,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('images/shoplist.png', width: 58, height: 58, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ShopList',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            'Gestão de compras',
                            style: TextStyle(color: scheme.onPrimaryContainer.withOpacity(0.72)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _drawerItem(Icons.dashboard_rounded, 'Principal', () => Navigator.pop(context), selected: true),
                  _drawerItem(
                    Icons.shopping_cart_checkout_rounded,
                    'As minhas compras',
                    () => _openFromDrawer(const ListItemsSelectedPage(title: 'As Minhas Compras')),
                  ),
                  _drawerItem(
                    Icons.playlist_add_check_circle_rounded,
                    'Seleção de compras',
                    () => _openFromDrawer(const ListItemsChoosePage()),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text('GESTÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ),
                  _drawerItem(Icons.format_list_bulleted_rounded, 'Listas', () => _openFromDrawer(const ListyPage(title: 'Listas'))),
                  _drawerItem(Icons.inventory_2_rounded, 'Itens', () => _openFromDrawer(const ItemPage(title: 'Catálogo de Itens'))),
                  _drawerItem(Icons.history_rounded, 'Histórico', () => _openFromDrawer(const HistoryListPage(title: 'Histórico de Listas'))),
                  _drawerItem(Icons.category_rounded, 'Categorias', () => _openFromDrawer(const CategoryPage(title: 'Categorias'))),
                  _drawerItem(Icons.straighten_rounded, 'Unidades', () => _openFromDrawer(const UnityPage(title: 'Unidades'))),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _drawerItem(
                Icons.settings_rounded,
                'Configurações',
                () => _openFromDrawer(const ConfigurationPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.primaryContainer,
        selectedColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _menuDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  PageContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          _errorBanner(),
                          const SizedBox(height: 14),
                        ],
                        _hero(),
                        const SizedBox(height: 22),
                        _statsGrid(),
                        const SizedBox(height: 26),
                        const SectionTitle(
                          'Ações rápidas',
                          subtitle: 'As tarefas mais usadas ficam a um toque de distância.',
                        ),
                        const SizedBox(height: 12),
                        _quickActions(),
                        const SizedBox(height: 30),
                        SectionTitle(
                          'Listas recentes',
                          subtitle: 'Continue onde ficou.',
                          trailing: TextButton(
                            onPressed: () => _openPage(const ListyPage(title: 'Listas')),
                            child: const Text('Ver todas'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_recentLists.isEmpty)
                          const SurfaceCard(
                            child: Text('Ainda não existem listas pessoais. Crie uma para começar.'),
                          )
                        else
                          ..._recentLists.map(_recentListCard),
                        if (_predefinedLists.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const SectionTitle(
                            'Listas predefinidas',
                            subtitle: 'Modelos prontos para acelerar as compras.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _predefinedLists.map(_predefinedChip).toList(),
                          ),
                        ],
                        if (_topCategories.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const SectionTitle(
                            'Categorias mais usadas',
                            subtitle: 'Uma visão rápida do seu catálogo.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _topCategories.map(_categoryChip).toList(),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const SectionTitle(
                          'Atividade recente',
                          subtitle: 'Últimas alterações realizadas na aplicação.',
                        ),
                        const SizedBox(height: 12),
                        if (_recentActions.isEmpty)
                          const SurfaceCard(child: Text('Sem atividade recente.'))
                        else
                          SurfaceCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                for (var i = 0; i < _recentActions.length; i++) ...[
                                  _actionItem(_recentActions[i]),
                                  if (i != _recentActions.length - 1) const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _hero() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compras organizadas, sem complicações.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _pendingItems == 0
                      ? 'Não tem itens pendentes neste momento.'
                      : 'Tem $_pendingItems ${_pendingItems == 1 ? 'item pendente' : 'itens pendentes'} para comprar.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                  ),
                  onPressed: () => _openPage(const ListItemsSelectedPage(title: 'As Minhas Compras')),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const Text('Abrir compras'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (MediaQuery.sizeOf(context).width > 520)
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset('images/shoplist.png', fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth >= 760 ? 1.7 : 1.45,
          children: [
            _statCard(Icons.pending_actions_rounded, 'Pendentes', _pendingItems.toString(), Theme.of(context).colorScheme.secondary),
            _statCard(Icons.playlist_play_rounded, 'Listas ativas', _activeLists.toString(), Theme.of(context).colorScheme.primary),
            _statCard(Icons.task_alt_rounded, 'Concluídas', _historyLists.toString(), Theme.of(context).colorScheme.tertiary),
            _statCard(Icons.inventory_2_rounded, 'Itens', _catalogItems.toString(), Theme.of(context).colorScheme.primary),
          ],
        );
      },
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 6),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (Icons.add_shopping_cart_rounded, 'Escolher itens', 'Monte uma lista', () => _openPage(const ListItemsChoosePage())),
      (Icons.shopping_bag_rounded, 'Minhas compras', 'Marque no supermercado', () => _openPage(const ListItemsSelectedPage(title: 'As Minhas Compras'))),
      (Icons.add_box_rounded, 'Gerir itens', 'Atualize o catálogo', () => _openPage(const ItemPage(title: 'Catálogo de Itens'))),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((action) {
            return SizedBox(
              width: width,
              child: SurfaceCard(
                onTap: action.$4,
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(action.$1, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            action.$3,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _recentListCard(Listy list) {
    final date = list.updatedAt ?? list.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        onTap: list.id == null ? null : () => _openPage(ListItemsPreviewPage(listId: list.id!)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.list_alt_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? 'Sem data' : 'Atualizada ${DateFormat('dd/MM/yyyy').format(date)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _predefinedChip(Listy list) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: Text(list.name),
      onPressed: list.id == null ? null : () => _openPage(ListItemsPreviewPage(listId: list.id!)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    );
  }

  Widget _categoryChip(Category category) {
    final color = categoryColor(context, category.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category.name), size: 18, color: color),
          const SizedBox(width: 7),
          Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionItem(Map<String, dynamic> action) {
    final message = action['message']?.toString() ?? '';
    final timestamp = action['timestamp'];
    final icon = message.startsWith('+')
        ? Icons.add_circle_outline_rounded
        : message.startsWith('-')
            ? Icons.remove_circle_outline_rounded
            : message.startsWith('✓')
                ? Icons.task_alt_rounded
                : Icons.edit_note_rounded;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(message.replaceFirst(RegExp(r'^[+\-~✓]\s*'), '')),
      subtitle: timestamp is DateTime
          ? Text(DateFormat('dd/MM · HH:mm').format(timestamp))
          : null,
    );
  }

  Widget _errorBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer))),
        ],
      ),
    );
  }
}
