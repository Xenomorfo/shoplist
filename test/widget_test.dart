import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplist/UI/app_widgets.dart';

void main() {
  testWidgets('EmptyState renders its content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Lista vazia',
            message: 'Adicione produtos para começar.',
          ),
        ),
      ),
    );

    expect(find.text('Lista vazia'), findsOneWidget);
    expect(find.text('Adicione produtos para começar.'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });
}
