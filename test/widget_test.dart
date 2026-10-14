import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/chat/presentation/chat_providers.dart';
import 'package:secondlife_app_seller/features/credits/domain/credit_models.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/features/listings/presentation/seller_listings_providers.dart';
import 'package:secondlife_app_seller/features/notifications/presentation/notification_providers.dart';
import 'package:secondlife_app_seller/features/orders/presentation/order_providers.dart';
import 'package:secondlife_app_seller/features/wallet/domain/wallet_models.dart';
import 'package:secondlife_app_seller/features/wallet/presentation/wallet_providers.dart';
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

class MockSellerListingsNotifier extends SellerListingsNotifier {
  @override
  SellerListingsState build() {
    return const SellerListingsState(isLoading: false);
  }
}

class MockSellerWalletNotifier extends SellerWalletNotifier {
  @override
  SellerWalletState build() {
    return SellerWalletState(
      isLoading: false,
      wallet: SellerWalletModel(
        id: 'w-1',
        userId: 'u-1',
        balance: 4500000,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class MockNotificationNotifier extends NotificationNotifier {
  @override
  NotificationState build() {
    return const NotificationState(isLoading: false, unreadCount: 2);
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
          sellerListingsNotifierProvider.overrideWith(MockSellerListingsNotifier.new),
          sellerWalletNotifierProvider.overrideWith(MockSellerWalletNotifier.new),
          notificationNotifierProvider.overrideWith(MockNotificationNotifier.new),
        ],
        child: const SecondLifeSellerApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(SecondLifeSellerApp), findsOneWidget);
  });
}
