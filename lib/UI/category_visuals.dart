import 'package:flutter/material.dart';

IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('fruta')) return Icons.apple_rounded;
  if (n.contains('legume')) return Icons.eco_rounded;
  if (n.contains('carne')) return Icons.restaurant_rounded;
  if (n.contains('peixe')) return Icons.set_meal_rounded;
  if (n.contains('bebida')) return Icons.local_drink_rounded;
  if (n.contains('latic')) return Icons.breakfast_dining_rounded;
  if (n.contains('padaria')) return Icons.bakery_dining_rounded;
  if (n.contains('congel')) return Icons.ac_unit_rounded;
  if (n.contains('higiene')) return Icons.sanitizer_rounded;
  if (n.contains('deterg') || n.contains('limpeza')) return Icons.cleaning_services_rounded;
  if (n.contains('utens')) return Icons.home_repair_service_rounded;
  if (n.contains('charcut')) return Icons.lunch_dining_rounded;
  if (n.contains('enlat')) return Icons.inventory_2_rounded;
  if (n.contains('mercearia')) return Icons.storefront_rounded;
  return Icons.category_rounded;
}

Color categoryColor(BuildContext context, String name) {
  final scheme = Theme.of(context).colorScheme;
  final n = name.toLowerCase();
  if (n.contains('fruta') || n.contains('legume')) return const Color(0xFF2E9D63);
  if (n.contains('carne') || n.contains('charcut')) return const Color(0xFFD65A5A);
  if (n.contains('peixe')) return const Color(0xFF3B82C4);
  if (n.contains('bebida')) return const Color(0xFF4F6FD8);
  if (n.contains('latic')) return const Color(0xFF7B6FD0);
  if (n.contains('padaria')) return const Color(0xFFC9863B);
  if (n.contains('congel')) return const Color(0xFF438AA3);
  if (n.contains('higiene') || n.contains('deterg')) return const Color(0xFF7B61A8);
  return scheme.primary;
}
