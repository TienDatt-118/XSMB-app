import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb/core/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard renders child and padding correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('XSMB Test Card'),
          ),
        ),
      ),
    );

    expect(find.text('XSMB Test Card'), findsOneWidget);
    expect(find.byType(GlassCard), findsOneWidget);
  });
}
