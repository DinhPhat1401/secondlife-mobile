import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/credits/domain/credit_models.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/main.dart';

class MockCreditNotifier extends CreditNotifier {
  @override
  CreditState build() {
    return const CreditState(
      balance: CreditBalanceModel(postCredits: 10, valuationCredits: 5),
    );
  }
}

void main() {
  testWidgets('App smoke test - verifies launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditNotifierProvider.overrideWith(MockCreditNotifier.new),
        ],
        child: const SecondLifeSellerApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(SecondLifeSellerApp), findsOneWidget);
  });
}
