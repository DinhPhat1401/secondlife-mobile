import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/chat/presentation/chat_providers.dart';
import 'package:secondlife_app_seller/features/credits/domain/credit_models.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/features/orders/presentation/order_providers.dart';
import 'package:secondlife_app_seller/main.dart';

class MockCreditNotifier extends CreditNotifier {
  @override
  CreditState build() {
    return const CreditState(
      balance: CreditBalanceModel(postCredits: 10, valuationCredits: 5),
    );
  }
}

class MockOrderListNotifier extends OrderListNotifier {
  @override
  OrderListState build() {
    return const OrderListState();
  }
}

class MockChatRoomsNotifier extends ChatRoomsNotifier {
  @override
  ChatRoomsState build() {
    return const ChatRoomsState();
  }
}

void main() {
  testWidgets('App smoke test - verifies launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditNotifierProvider.overrideWith(MockCreditNotifier.new),
          orderListNotifierProvider.overrideWith(MockOrderListNotifier.new),
          chatRoomsNotifierProvider.overrideWith(MockChatRoomsNotifier.new),
        ],
        child: const SecondLifeSellerApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(SecondLifeSellerApp), findsOneWidget);
  });
}
