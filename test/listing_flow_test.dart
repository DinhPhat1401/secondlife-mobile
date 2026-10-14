import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/catalog/domain/catalog_models.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

void main() {
  group('Catalog Models Tests', () {
    test('Parses CategoryModel and ItemModel from JSON', () {
      final catJson = {
        'id': 'cat-kitchen',
        'name': 'Bếp & Phòng Ăn',
        'code': 'KITCHEN',
      };
      final cat = CategoryModel.fromJson(catJson);
      expect(cat.id, 'cat-kitchen');
      expect(cat.name, 'Bếp & Phòng Ăn');

      final itemJson = {
        'id': 'itm-airfryer',
        'categoryId': 'cat-kitchen',
        'name': 'Nồi chiên không dầu',
      };
      final itm = ItemModel.fromJson(itemJson);
      expect(itm.id, 'itm-airfryer');
      expect(itm.categoryId, 'cat-kitchen');
      expect(itm.name, 'Nồi chiên không dầu');
    });
  });

  group('Post Models & ApplianceCondition Tests', () {
    test('Correctly maps ApplianceCondition codes and labels', () {
      expect(ApplianceCondition.fromCode('LIKE_NEW'), ApplianceCondition.likeNew);
      expect(ApplianceCondition.fromCode('USED_GOOD'), ApplianceCondition.usedGood);
      expect(ApplianceCondition.fromCode('USED_FAIR'), ApplianceCondition.usedFair);
      expect(ApplianceCondition.fromCode('UNKNOWN'), ApplianceCondition.usedGood);
    });

    test('Parses PostInitResponseModel and questions', () {
      final json = {
        'postId': 'post-1234',
        'aiSessionId': 'session-5678',
        'initialMessage': 'Xin chào, tôi là trợ lý AI. Vui lòng cho biết nồi chiên đã mua bao lâu?',
        'suggestedQuestions': [
          'Máy hoạt động tốt không?',
          'Còn phụ kiện khay lưới không?',
        ],
        'visualReport': 'Tem thông số Panasonic NF-CC600',
      };

      final res = PostInitResponseModel.fromJson(json);

      expect(res.postId, 'post-1234');
      expect(res.aiSessionId, 'session-5678');
      expect(res.suggestedQuestions.length, 2);
      expect(res.suggestedQuestions.first, 'Máy hoạt động tốt không?');
    });

    test('Parses AiPriceEstimationModel correctly', () {
      final json = {
        'estimatedPrice': 950000.0,
        'priceMin': 800000.0,
        'priceMax': 1100000.0,
        'confidence': 0.92,
        'reasoning': 'Dựa trên 24 giao dịch nồi chiên Panasonic tương tự đã bán thành công trong tháng qua.',
        'currency': 'VND',
      };

      final est = AiPriceEstimationModel.fromJson(json);

      expect(est.estimatedPrice, 950000.0);
      expect(est.priceMin, 800000.0);
      expect(est.priceMax, 1100000.0);
      expect(est.confidence, 0.92);
    });

    test('ShippingPackageModel converts to JSON for Lalamove integration', () {
      const pkg = ShippingPackageModel(
        weightGrams: 3500,
        lengthCm: 32,
        widthCm: 32,
        heightCm: 38,
      );

      final json = pkg.toJson();

      expect(json['packageWeightGrams'], 3500);
      expect(json['packageLengthCm'], 32);
      expect(json['packageWidthCm'], 32);
      expect(json['packageHeightCm'], 38);
    });
  });

  group('CreateListingState Tests', () {
    test('State copyWith updates step and properties smoothly', () {
      const state = CreateListingState(step: 0);
      final updated = state.copyWith(
        step: 3,
        title: 'Nồi cơm điện Cuckoo 1.8L',
        userPriceVnd: 1200000,
      );

      expect(updated.step, 3);
      expect(updated.title, 'Nồi cơm điện Cuckoo 1.8L');
      expect(updated.userPriceVnd, 1200000);
    });
  });
}
