import '../data_model.dart';

class HistoryList implements DataModel {
  @override
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? endedAt;
  final int? totalItems;
  final int? totalBought;

  @override
  String get tableName => 'historyLists';

  const HistoryList({
    this.id,
    required this.name,
    this.createdAt,
    this.endedAt,
    required this.totalItems,
    required this.totalBought,
  });

  factory HistoryList.fromMap(Map<String, dynamic> map) {
    return HistoryList(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? 'Lista sem nome',
      createdAt: _dateFromDb(map['createdAt']),
      endedAt: _dateFromDb(map['endedAt']),
      totalItems: _intFromDb(map['totalItems']),
      totalBought: _intFromDb(map['totalBought']),
    );
  }

  static DateTime? _dateFromDb(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int? _intFromDb(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  bool operator ==(Object other) => other is HistoryList && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'createdAt': createdAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'totalItems': totalItems,
      'totalBought': totalBought,
    };
  }
}
