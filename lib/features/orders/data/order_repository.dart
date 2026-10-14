import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/api_response.dart';
import '../domain/order_models.dart';

class OrderRepository {
  final ApiClient client;

  OrderRepository({required this.client});

  Future<PageResponse<SellerOrderModel>> getSellerOrders({
    OrderStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null && status != OrderStatus.unknown) {
      queryParams['status'] = status.code;
    }

    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.ordersSeller,
      queryParameters: queryParams,
    );

    return PageResponse.fromJson(
      response.data ?? {},
      (json) => SellerOrderModel.fromJson(json),
    );
  }

  Future<SellerOrderModel> markAsShipped(String orderId) async {
    final response = await client.put<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/shipped',
    );
    return SellerOrderModel.fromJson(response.data!);
  }

  Future<SellerOrderModel> cancelOrder(String orderId, [String? reason]) async {
    final response = await client.put<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    return SellerOrderModel.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> getCommission(String orderId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.orderCommission(orderId),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getSettlement(String orderId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.orderSettlement(orderId),
    );
    return response.data ?? {};
  }
}
