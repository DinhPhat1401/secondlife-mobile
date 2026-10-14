import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/api_response.dart';
import '../domain/credit_models.dart';

class CreditRepository {
  final ApiClient client;

  CreditRepository({required this.client});

  Future<CreditBalanceModel> getCredits() async {
    try {
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.sellerCredits);
      if (response.data == null) {
        return const CreditBalanceModel();
      }
      return CreditBalanceModel.fromJson(response.data!);
    } catch (_) {
      return const CreditBalanceModel();
    }
  }

  Future<Map<String, dynamic>> getPricing({
    int? listingQuantity,
    int? valuationQuantity,
  }) async {
    final queryParams = <String, dynamic>{};
    if (listingQuantity != null) queryParams['listingQuantity'] = listingQuantity;
    if (valuationQuantity != null) queryParams['valuationQuantity'] = valuationQuantity;

    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.sellerCreditPricing,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data ?? {};
    final prices = (data['prices'] as List<dynamic>? ?? [])
        .map((p) => CreditPricingRuleModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final discountTiers = (data['discountTiers'] as List<dynamic>? ?? [])
        .map((t) => CreditDiscountTierModel.fromJson(t as Map<String, dynamic>))
        .toList();

    CreditQuoteModel? quote;
    if (data['quote'] != null) {
      quote = CreditQuoteModel.fromJson(data['quote'] as Map<String, dynamic>);
    }

    return {
      'prices': prices,
      'discountTiers': discountTiers,
      'quote': quote,
    };
  }

  Future<CreditPurchaseModel> createPurchase({
    required int listingQuantity,
    required int valuationQuantity,
    int aiChatQuantity = 0,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.sellerCreditPurchases,
      data: {
        'listingQuantity': listingQuantity,
        'valuationQuantity': valuationQuantity,
        'aiChatQuantity': aiChatQuantity,
      },
    );

    return CreditPurchaseModel.fromJson(response.data!);
  }

  Future<PageResponse<CreditLedgerItemModel>> getLedger({
    int page = 0,
    int size = 20,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.sellerCreditLedger,
      queryParameters: {'page': page, 'size': size},
    );

    return PageResponse.fromJson(
      response.data ?? {},
      (json) => CreditLedgerItemModel.fromJson(json),
    );
  }

  Future<PageResponse<CreditPurchaseModel>> getPurchases({
    int page = 0,
    int size = 20,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.sellerCreditPurchases,
      queryParameters: {'page': page, 'size': size},
    );

    return PageResponse.fromJson(
      response.data ?? {},
      (json) => CreditPurchaseModel.fromJson(json),
    );
  }
}
