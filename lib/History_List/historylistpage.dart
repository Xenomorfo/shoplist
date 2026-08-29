import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../UI/app_widgets.dart';
import 'historylist.dart';
import 'historylist_repository.dart';
import 'historylistdetailspage.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({super.key, required this.title});

  final String title;

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  final _searchController = TextEditingController();
  List<HistoryList> _history = [];
  bool _loading = true;
  String _query = '';

  List<HistoryList> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _history;
    return _history.where((h) => h.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    final history = await historyListRepoService.fetchHistoryList();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _deleteHistory(HistoryList history) async {
    if (history.id == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Apagar histórico?',
      message: 'O registo “${history.name}” e os seus itens serão removidos definitivamente.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!confirmed) return;
    await historyListRepoService.deleteHistoryList(history.id!);
    await _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Histórico de compras',
                    subtitle: '${_history.length} ${_history.length == 1 ? 'lista concluída' : 'listas concluídas'}',
                  ),
                  const SizedBox(height: 14),
                  SearchBox(
                    controller: _searchController,
                    hintText: 'Pesquisar no histórico...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.history_rounded,
                            title: _history.isEmpty ? 'Ainda não existe histórico' : 'Nenhum resultado',
                            message: _history.isEmpty
                                ? 'As listas concluídas irão aparecer aqui automaticamente.'
                                : 'Tente pesquisar por outro nome.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchHistory,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) => _historyCard(_filtered[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _historyCard(HistoryList history) {
    final total = history.totalItems ?? 0;
    final bought = history.totalBought ?? 0;
    final progress = total <= 0 ? 0.0 : (bought / total).clamp(0.0, 1.0).toDouble();
    final ended = history.endedAt;
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      onTap: history.id == null
          ? null
          : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HistoryListDetailsPage(listId: history.id!)),
              );
              await _fetchHistory();
            },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.task_alt_rounded, color: scheme.onTertiaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(
                  '${ended == null ? 'Sem data' : DateFormat('dd/MM/yyyy · HH:mm').format(ended)}  ·  $bought/$total comprados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress, minHeight: 5),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteHistory(history);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Apagar')),
              ),
            ],
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
