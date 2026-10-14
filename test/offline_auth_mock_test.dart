import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/auth/data/auth_repository.dart';
import 'package:secondlife_app_seller/features/catalog/data/catalog_repository.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> mockStorageData = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          final key = methodCall.arguments['key'] as String?;
          final val = methodCall.arguments['value'] as String?;
          if (key != null && val != null) {
            mockStorageData[key] = val;
          }
          return null;
        } else if (methodCall.method == 'read') {
          final key = methodCall.arguments['key'] as String?;
          return key != null ? mockStorageData[key] : null;
        } else if (methodCall.method == 'delete') {
          final key = methodCall.arguments['key'] as String?;
          if (key != null) {
            mockStorageData.remove(key);
          }
          return null;
        }
        return null;
      },
    );
  });

  group('Offline / Demo Auth & Catalog Tests (No DB needed)', () {
    late ApiClient apiClient;
    late SecureStorageService storage;
    late AuthRepository authRepository;
    late CatalogRepository catalogRepository;

    setUp(() {
      storage = SecureStorageService();
      apiClient = ApiClient(storageService: storage);
      authRepository = AuthRepository(client: apiClient, storage: storage);
      catalogRepository = CatalogRepository(client: apiClient);
    });

    test('Login succeeds with any valid email and password >= 6 characters', () async {
      final user = await authRepository.login(
        email: 'seller.test@secondlife.vn',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user.email, equals('seller.test@secondlife.vn'));
      expect(user.isSeller, isTrue);
      expect(user.roles, contains('SELLER'));
      expect(user.accountStatus, equals('ACTIVE'));
    });

    test('Register succeeds with valid email and password >= 6 characters without DB', () async {
      final user = await authRepository.register(
        email: 'newuser@gmail.com',
        password: 'secretPassword',
        fullName: 'Nguyễn Văn Bán',
        phone: '0987654321',
      );

      expect(user, isNotNull);
      expect(user.email, equals('newuser@gmail.com'));
      expect(user.fullName, equals('Nguyễn Văn Bán'));
      expect(user.isSeller, isTrue);
    });

    test('Login throws exception when email has invalid format or password is too short', () async {
      expect(
        () => authRepository.login(
          email: 'invalid-email-no-at',
          password: '123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('CatalogRepository returns default categories and items when backend is offline', () async {
      final categories = await catalogRepository.getCategories();
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name.contains('Tủ lạnh')), isTrue);

      final items = await catalogRepository.getItemsByCategory('cat-refrigerator');
      expect(items, isNotEmpty);
      expect(items.first.name, contains('Tủ lạnh'));
    });
  });
}
