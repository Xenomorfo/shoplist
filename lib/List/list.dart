import '../data_model.dart';

class Listy implements DataModel {
  @override
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPredefined;

  @override
  String get tableName => 'lists';

  const Listy({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.isPredefined = false,
  });

  factory Listy.fromMap(Map<String, dynamic> map) {
    return Listy(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      createdAt: _dateFromDb(map['createdAt']),
      updatedAt: _dateFromDb(map['updatedAt']),
      isPredefined: _boolFromDb(map['isPredefined']),
    );
  }

  static DateTime? _dateFromDb(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _boolFromDb(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  @override
  bool operator ==(Object other) => other is Listy && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPredefined': isPredefined ? 1 : 0,
    };
  }
}
