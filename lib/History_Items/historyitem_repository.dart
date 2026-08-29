import '../Database/database_provider.dart';
import 'historyitem.dart';

final historyItemRepository = DatabaseProvider<HistoryItem>(
  tableName: 'historyItems',
  fromMap: HistoryItem.fromMap,
);

class HistoryItemRepositoryService {
  Future<List<HistoryItem>> fetchHistoryItens() =>
      historyItemRepository.queryAll(orderBy: 'id ASC');

  Future<int> addHistoryItem(HistoryItem historyItem) =>
      historyItemRepository.insert(historyItem);

  Future<HistoryItem?> fetchOneHistoryItem(int id) =>
      historyItemRepository.queryById(id);

  Future<int> updateHistoryItem(HistoryItem historyItem) =>
      historyItemRepository.update(historyItem);

  Future<int> deleteHistoryItem(int id) => historyItemRepository.delete(id);
}

final historyItemRepoService = HistoryItemRepositoryService();
