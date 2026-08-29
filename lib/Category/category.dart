import '../data_model.dart';

class Category implements DataModel {
  @override
  final int? id;
  final String name;
  final String? icon;
  final String? color;
  final bool isActive;

  @override
  String get tableName => 'categories';

  const Category({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.isActive = true,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: _boolFromDb(map['isActive'], fallback: true),
    );
  }

  static bool _boolFromDb(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'icon': icon,
      'color': color,
      'isActive': isActive ? 1 : 0,
    };
  }
}
