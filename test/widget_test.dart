import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/main.dart';

void main() {
  testWidgets('App smoke test - verifies launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SecondLifeSellerApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(SecondLifeSellerApp), findsOneWidget);
  });
}
