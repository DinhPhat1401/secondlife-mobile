import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/screens/seller_listings_screen.dart';
import 'package:secondlife_app_seller/features/listings/presentation/seller_listings_providers.dart';
import 'package:secondlife_app_seller/features/wallet/domain/wallet_models.dart';
import 'package:secondlife_app_seller/features/wallet/presentation/screens/seller_wallet_screen.dart';
import 'package:secondlife_app_seller/features/wallet/presentation/wallet_providers.dart';
import 'package:secondlife_app_seller/features/notifications/domain/notification_models.dart';
import 'package:secondlife_app_seller/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:secondlife_app_seller/features/notifications/presentation/notification_providers.dart';
import 'package:secondlife_app_seller/features/shipments/domain/tamper_seal_model.dart';

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
        balance: 3500000.0,
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
  group('Sprint 5 - Seller Listings Management Tests', () {
    test('Correctly maps ListingStatus strings to enum', () {
      expect(ListingStatus.fromCode('ACTIVE'), ListingStatus.active);
      expect(ListingStatus.fromCode('PENDING'), ListingStatus.pending);
      expect(ListingStatus.fromCode('RESERVED'), ListingStatus.reserved);
      expect(ListingStatus.fromCode('SOLD'), ListingStatus.sold);
      expect(ListingStatus.fromCode('DRAFT'), ListingStatus.draft);
      expect(ListingStatus.fromCode('REJECTED'), ListingStatus.rejected);
      expect(ListingStatus.fromCode('UNKNOWN'), ListingStatus.active);
    });

    test('Parses SellerListingItemModel from JSON correctly', () {
      final json = {
        'id': 'post-101',
        'title': 'Máy giặt sấy LG Inverter 9kg',
        'description': 'Hoạt động hoàn hảo, còn tem bảo hành',
        'price': 6500000,
        'itemCondition': 'LIKE_NEW',
        'imageUrls': ['https://example.com/lg.jpg'],
        'status': 'RESERVED',
        'rejectionReason': null,
        'listingCreditCharged': true,
        'aiSuggestedPrice': 6700000,
        'shippingWeight': 70000,
        'createdAt': '2026-10-14T08:00:00Z',
      };

      final item = SellerListingItemModel.fromJson(json);

      expect(item.id, 'post-101');
      expect(item.title, 'Máy giặt sấy LG Inverter 9kg');
      expect(item.price, 6500000.0);
      expect(item.itemCondition, ApplianceCondition.likeNew);
      expect(item.status, ListingStatus.reserved);
      expect(item.primaryImageUrl, 'https://example.com/lg.jpg');
      expect(item.shippingWeight, 70000);
      expect(item.listingCreditCharged, true);
    });

    test('SellerListingItemModel fallback image when imageUrls empty', () {
      final item = SellerListingItemModel(
        id: 'post-102',
        title: 'Bếp điện từ đôi Kangaroo',
        price: 1500000,
        imageUrls: const [],
      );

      expect(item.primaryImageUrl, isNotEmpty);
      expect(item.primaryImageUrl.contains('unsplash'), true);
    });
  });

  group('Sprint 5 - Wallet & Withdrawal Models Tests', () {
    test('Parses SellerWalletModel correctly', () {
      final json = {
        'id': 'wallet-123',
        'userId': 'user-456',
        'balance': 3500000.0,
        'pendingBalance': 1200000.0,
        'totalWithdrawn': 8000000.0,
        'updatedAt': '2026-10-14T10:00:00Z',
      };

      final wallet = SellerWalletModel.fromJson(json);
      expect(wallet.id, 'wallet-123');
      expect(wallet.balance, 3500000.0);
      expect(wallet.pendingBalance, 1200000.0);
      expect(wallet.totalWithdrawn, 8000000.0);
    });

    test('Parses WalletTransactionModel and type flag', () {
      final json = {
        'id': 'tx-1',
        'amount': 2500000.0,
        'type': 'ORDER_PAYOUT',
        'description': 'Tiền bán hàng đơn ORD-1',
        'referenceId': 'ORD-1',
        'balanceAfter': 5000000.0,
        'createdAt': '2026-10-14T11:00:00Z',
      };

      final tx = WalletTransactionModel.fromJson(json);
      expect(tx.type, WalletTransactionType.orderPayout);
      expect(tx.type.isCredit, true);
      expect(tx.amount, 2500000.0);
      expect(tx.referenceId, 'ORD-1');
    });

    test('Parses WalletWithdrawalModel with status and rejection note', () {
      final json = {
        'id': 'wd-1',
        'amount': 1000000.0,
        'bankCode': 'VCB',
        'bankName': 'Vietcombank',
        'accountNumber': '0123456789',
        'accountHolderName': 'TRAN VAN A',
        'status': 'REJECTED',
        'adminNote': 'Sai tên chủ tài khoản',
        'createdAt': '2026-10-14T09:00:00Z',
      };

      final wd = WalletWithdrawalModel.fromJson(json);
      expect(wd.bankCode, 'VCB');
      expect(wd.status, WithdrawalStatus.rejected);
      expect(wd.adminNote, 'Sai tên chủ tài khoản');
      expect(wd.accountHolderName, 'TRAN VAN A');
    });

    test('SupportedBank list contains key VN banks', () {
      final codes = SupportedBank.list.map((b) => b.code).toList();
      expect(codes, contains('VCB'));
      expect(codes, contains('MB'));
      expect(codes, contains('TCB'));
      expect(codes, contains('ACB'));
    });
  });

  group('Sprint 5 - Notifications Models Tests', () {
    test('Maps NotificationType correctly', () {
      expect(NotificationType.fromCode('ORDER'), NotificationType.order);
      expect(NotificationType.fromCode('NEGOTIATION'), NotificationType.negotiation);
      expect(NotificationType.fromCode('CHAT'), NotificationType.chat);
      expect(NotificationType.fromCode('WALLET'), NotificationType.wallet);
      expect(NotificationType.fromCode('INSPECTION'), NotificationType.inspection);
      expect(NotificationType.fromCode('SYSTEM'), NotificationType.system);
    });

    test('Parses NotificationModel with deep linking targetUrl', () {
      final json = {
        'id': 'notif-100',
        'title': 'Đơn hàng mới #ORD-999',
        'body': 'Người mua đã thanh toán giữ chỗ thành công.',
        'type': 'ORDER',
        'isRead': false,
        'referenceId': 'ord-999',
        'targetUrl': '/orders',
        'createdAt': '2026-10-14T12:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.title, 'Đơn hàng mới #ORD-999');
      expect(notif.isRead, false);
      expect(notif.type, NotificationType.order);
      expect(notif.targetUrl, '/orders');
    });
  });

  group('Sprint 5 - Tamper-Evident Seal Model Tests', () {
    test('Parses TamperSealModel and verifies intact status', () {
      final json = {
        'tamperSealId': 'SL-SEAL-20261014-9988',
        'status': 'ACTIVE',
        'productTitle': 'Tủ lạnh Panasonic Inverter',
        'orderCode': 'ORD-8821',
        'centerName': 'Trung tâm kiểm định SecondLife Cầu Giấy',
        'inspectorName': 'Nguyễn Văn Kỹ Thuật',
        'inspectionDate': '2026-10-14T08:30:00Z',
        'sealCondition': 'INTACT',
        'notes': 'Tem niêm phong bảo an nguyên vẹn',
      };

      final seal = TamperSealModel.fromJson(json);
      expect(seal.tamperSealId, 'SL-SEAL-20261014-9988');
      expect(seal.isIntact, true);
      expect(seal.centerName, 'Trung tâm kiểm định SecondLife Cầu Giấy');
    });

    test('Detects tampered seal condition', () {
      final seal = TamperSealModel(
        tamperSealId: 'SL-SEAL-BROKEN',
        status: 'TAMPERED',
        productTitle: 'Máy giặt Electrolux',
        centerName: 'Trung tâm SecondLife',
        inspectorName: 'KTV Nam',
        inspectionDate: DateTime.now(),
        sealCondition: 'TAMPERED',
      );

      expect(seal.isIntact, false);
    });
  });

  group('Sprint 5 - Widget Smoke Tests', () {
    testWidgets('Renders SellerListingsScreen without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerListingsNotifierProvider.overrideWith(MockSellerListingsNotifier.new),
          ],
          child: const MaterialApp(
            home: SellerListingsScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Quản Lý Tin Đăng'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
    });

    testWidgets('Renders SellerWalletScreen without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerWalletNotifierProvider.overrideWith(MockSellerWalletNotifier.new),
          ],
          child: const MaterialApp(
            home: SellerWalletScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Ví Doanh Thu Người Bán'), findsOneWidget);
      expect(find.text('Số dư khả dụng'), findsOneWidget);
      expect(find.text('Yêu Cầu Rút Tiền Về Ngân Hàng'), findsOneWidget);
    });

    testWidgets('Renders NotificationCenterScreen without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationNotifierProvider.overrideWith(MockNotificationNotifier.new),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Thông Báo'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
    });
  });
}
