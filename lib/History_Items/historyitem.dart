import '../data_model.dart';

class HistoryItem implements DataModel {
  @override
  final int? id;
  final int? listHistoryId;
  final String? name;
  final double? qty;
  final int? unityId;
  final int? categoryId;
  final bool wasBought;

  @override
  String get tableName => 'historyItems';

  const HistoryItem({
    this.id,
    this.listHistoryId,
    required this.name,
    required this.qty,
    required this.unityId,
    required this.categoryId,
    this.wasBought = false,
  });

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      listHistoryId: map['listHistoryId'] as int?,
      name: map['name'] as String?,
      qty: _doubleFromDb(map['qty']),
      unityId: map['unityId'] as int?,
      categoryId: map['categoryId'] as int?,
      wasBought: _boolFromDb(map['wasBought']),
    );
  }

  static double? _doubleFromDb(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _boolFromDb(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listHistoryId': listHistoryId,
      'name': name?.trim(),
      'qty': qty,
      'unityId': unityId,
      'categoryId': categoryId,
      'wasBought': wasBought ? 1 : 0,
    };
  }
}
