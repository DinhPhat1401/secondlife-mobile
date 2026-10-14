import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/credits/domain/credit_models.dart';

void main() {
  group('Credit Models Tests', () {
    test('Parses CreditBalanceModel from JSON correctly', () {
      final json = {
        'postCredits': 12,
        'valuationCredits': 8,
        'chatCredits': 25,
      };

      final model = CreditBalanceModel.fromJson(json);

      expect(model.postCredits, 12);
      expect(model.valuationCredits, 8);
      expect(model.chatCredits, 25);
    });

    test('Parses CreditDiscountTierModel and calculates discountPercent', () {
      final json = {
        'id': 'tier-1',
        'minQuantity': 10,
        'maxQuantity': 19,
        'discountRate': 0.15,
        'active': true,
      };

      final tier = CreditDiscountTierModel.fromJson(json);

      expect(tier.id, 'tier-1');
      expect(tier.minQuantity, 10);
      expect(tier.maxQuantity, 19);
      expect(tier.discountRate, 0.15);
      expect(tier.discountPercent, 15);
    });

    test('Parses CreditQuoteModel with discount amounts', () {
      final json = {
        'listingQuantity': 10,
        'valuationQuantity': 10,
        'listingUnitPrice': 10000.0,
        'valuationUnitPrice': 5000.0,
        'discountRate': 0.10,
        'subtotal': 150000.0,
        'discountAmount': 15000.0,
        'finalFee': 135000.0,
        'currency': 'VND',
      };

      final quote = CreditQuoteModel.fromJson(json);

      expect(quote.listingQuantity, 10);
      expect(quote.valuationQuantity, 10);
      expect(quote.subtotal, 150000.0);
      expect(quote.discountAmount, 15000.0);
      expect(quote.finalFee, 135000.0);
    });

    test('Parses CreditLedgerItemModel correctly', () {
      final json = {
        'id': 'led-001',
        'creditType': 'LISTING',
        'entryType': 'PURCHASE',
        'quantityDelta': 10,
        'balanceAfter': 15,
        'createdAt': '2026-10-14 12:00:00',
      };

      final item = CreditLedgerItemModel.fromJson(json);

      expect(item.id, 'led-001');
      expect(item.creditType, 'LISTING');
      expect(item.isPositive, true);
      expect(item.entryTypeLabel, 'Nạp gói tín dụng');
      expect(item.quantityDelta, 10);
      expect(item.balanceAfter, 15);
    });
  });
}
