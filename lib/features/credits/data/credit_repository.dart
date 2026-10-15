import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/api_response.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import '../domain/credit_models.dart';

class CreditRepository {
  final ApiClient client;

  CreditRepository({required this.client});

  Future<CreditBalanceModel> getCredits() async {
    final response = await client.get<Map<String, dynamic>>(ApiEndpoints.sellerCredits);
    if (response.data == null) {
      throw AppException(message: 'Không nhận được dữ liệu số dư credit từ máy chủ');
    }
    final payload = response.data!['data'] ?? response.data!;
    return CreditBalanceModel.fromJson(payload as Map<String, dynamic>);
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
      queryParameters: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
    );

    final pageRes = PageResponse.fromJson(
      response.data ?? {},
      (json) => CreditLedgerItemModel.fromJson(json),
    );
    pageRes.items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pageRes;
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

  Future<List<TopupPackageModel>> getTopupPackages() async {
    final response = await client.get<dynamic>(ApiEndpoints.topupPackages);
    final data = response.data;
    List list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    }
    return list.map((e) => TopupPackageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreditBalanceModel> purchaseTopupPackage(String packageId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.topupPurchase(packageId),
    );
    final payload = response.data!['data'] ?? response.data!;
    return CreditBalanceModel.fromJson(payload as Map<String, dynamic>);
  }
}
