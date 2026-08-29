import '../Database/database_provider.dart';
import '../Database/databasehelper.dart';
import '../History_Items/historyitem.dart';
import '../Item/item.dart';
import '../List/list.dart';
import '../Shopping/list_item.dart';
import '../actionloggerservice.dart';
import 'historylist.dart';

final historyListRepository = DatabaseProvider<HistoryList>(
  tableName: 'historyLists',
  fromMap: HistoryList.fromMap,
);

class HistoryListRepositoryService {
  final action = const ActionLoggerService();

  Future<List<HistoryList>> fetchHistoryList() =>
      historyListRepository.queryAll(orderBy: 'endedAt DESC, id DESC');

  Future<int> addHistoryList(HistoryList historyList) async {
    final id = await historyListRepository.insert(historyList);
    await action.addAction('✓ Concluiu ${historyList.name}');
    return id;
  }

  Future<HistoryList?> fetchOneHistoryList(int id) =>
      historyListRepository.queryById(id);

  Future<int> updateHistoryList(HistoryList historyList) async {
    final result = await historyListRepository.update(historyList);
    if (result > 0) await action.addAction('~ Alterou ${historyList.name}');
    return result;
  }

  /// Arquiva uma lista e os seus itens numa única transação.
  /// Se qualquer escrita falhar, nenhuma parte da conclusão fica gravada.
  Future<int> archiveShoppingList({
    required Listy sourceList,
    required List<ListItem> shoppingItems,
    required Map<int, Item> catalogById,
  }) async {
    final sourceListId = sourceList.id;
    if (sourceListId == null || shoppingItems.isEmpty) {
      throw StateError('A lista não tem dados válidos para arquivar.');
    }

    final database = await DatabaseHelper.instance.db;
    final endedAt = DateTime.now();
    final totalBought = shoppingItems.where((item) => item.isChecked).length;

    final historyId = await database.transaction<int>((txn) async {
      final history = HistoryList(
        name: sourceList.name,
        createdAt: sourceList.createdAt ?? endedAt,
        endedAt: endedAt,
        totalItems: shoppingItems.length,
        totalBought: totalBought,
      );
      final historyValues = Map<String, dynamic>.from(history.toMap())..remove('id');
      final id = await txn.insert('historyLists', historyValues);

      for (final listItem in shoppingItems) {
        final item = catalogById[listItem.itemId];
        final historyItem = HistoryItem(
          listHistoryId: id,
          name: item?.name ?? 'Item removido',
          qty: listItem.qty ?? item?.qty ?? 1,
          unityId: item?.unityId,
          categoryId: item?.categoryId,
          wasBought: listItem.isChecked,
        );
        final values = Map<String, dynamic>.from(historyItem.toMap())..remove('id');
        await txn.insert('historyItems', values);
      }

      await txn.delete(
        'listItems',
        where: 'listId = ?',
        whereArgs: [sourceListId],
      );
      return id;
    });

    await action.addAction('✓ Concluiu ${sourceList.name}');
    return historyId;
  }

  Future<int> deleteHistoryList(int id) async {
    final database = await DatabaseHelper.instance.db;
    final history = await fetchOneHistoryList(id);

    final result = await database.transaction((txn) async {
      await txn.delete('historyItems', where: 'listHistoryId = ?', whereArgs: [id]);
      return txn.delete('historyLists', where: 'id = ?', whereArgs: [id]);
    });

    if (result > 0 && history != null) {
      await action.addAction('- Apagou histórico ${history.name}');
    }
    return result;
  }
}

final historyListRepoService = HistoryListRepositoryService();
