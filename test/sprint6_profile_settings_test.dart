import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/profile/domain/profile_models.dart';
import 'package:secondlife_app_seller/features/profile/presentation/profile_providers.dart';
import 'package:secondlife_app_seller/features/profile/presentation/screens/seller_profile_screen.dart';

class MockProfileNotifier extends ProfileNotifier {
  @override
  ProfileState build() {
    return ProfileState(
      isLoading: false,
      profile: SellerProfileModel(
        id: 'usr-001',
        email: 'seller@secondlife.vn',
        fullName: 'Cửa Hàng Gia Dụng Test',
        phone: '0901234567',
        isSeller: true,
        streetAddress: 'Số 10 Tràng Tiền',
        ward: 'Tràng Tiền',
        district: 'Hoàn Kiếm',
        province: 'Hà Nội',
        latitude: 21.0255,
        longitude: 105.8555,
        createdAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  group('Sprint 6 - Seller Profile & Settings Model Tests', () {
    test('Parses SellerProfileModel correctly from JSON', () {
      final json = {
        'id': 'usr-888',
        'email': 'seller888@test.com',
        'fullName': 'Shop Đồ Cũ Ba Đình',
        'phone': '0912345678',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'accountStatus': 'ACTIVE',
        'emailVerified': true,
        'roles': ['ROLE_SELLER', 'ROLE_BUYER'],
        'streetAddress': '15 Liễu Giai',
        'ward': 'Liễu Giai',
        'district': 'Ba Đình',
        'province': 'Hà Nội',
        'latitude': 21.0333,
        'longitude': 105.8167,
        'createdAt': '2026-10-14T00:00:00Z',
      };

      final profile = SellerProfileModel.fromJson(json);

      expect(profile.id, 'usr-888');
      expect(profile.fullName, 'Shop Đồ Cũ Ba Đình');
      expect(profile.isSeller, true);
      expect(profile.latitude, 21.0333);
      expect(profile.longitude, 105.8167);
      expect(profile.fullAddress, '15 Liễu Giai, Liễu Giai, Ba Đình, Hà Nội');
      expect(profile.displayAvatarUrl, 'https://example.com/avatar.jpg');
    });

    test('SellerProfileModel fullAddress handles missing address fields gracefully', () {
      const profile = SellerProfileModel(
        id: 'usr-empty',
        email: 'empty@test.com',
        fullName: 'Người bán mới',
      );

      expect(profile.fullAddress, 'Chưa thiết lập địa chỉ kho');
      expect(profile.displayAvatarUrl, isNotEmpty);
    });

    test('UpdateProfileRequestModel converts to JSON properly', () {
      const req = UpdateProfileRequestModel(
        fullName: 'Shop Mới Cập Nhật',
        phone: '0988776655',
        streetAddress: 'Tòa nhà FPT',
        latitude: 21.0315,
        longitude: 105.7836,
      );

      final json = req.toJson();
      expect(json['fullName'], 'Shop Mới Cập Nhật');
      expect(json['phone'], '0988776655');
      expect(json['streetAddress'], 'Tòa nhà FPT');
      expect(json['latitude'], 21.0315);
      expect(json['longitude'], 105.7836);
    });
  });

  group('Sprint 6 - Widget Smoke Tests', () {
    testWidgets('Renders SellerProfileScreen without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileNotifierProvider.overrideWith(MockProfileNotifier.new),
          ],
          child: const MaterialApp(
            home: SellerProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Hồ Sơ & Cài Đặt Shop'), findsOneWidget);
      expect(find.text('Cửa Hàng Gia Dụng Test'), findsOneWidget);
      expect(find.text('Kho Hàng & Giao Vận Lalamove'), findsOneWidget);
      expect(find.text('Shop Đã Xác Thực eKYC'), findsOneWidget);
      expect(find.text('Đổi Mật Khẩu'), findsOneWidget);
      expect(find.text('Đăng Xuất Tài Khoản'), findsOneWidget);
    });
  });
}
