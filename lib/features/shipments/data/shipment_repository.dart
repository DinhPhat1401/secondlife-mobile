import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import '../domain/shipment_models.dart';
import '../domain/tamper_seal_model.dart';

class ShipmentRepository {
  final ApiClient client;

  ShipmentRepository({required this.client});

  Future<ShipmentTrackingModel> getTracking(String shipmentId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.shipmentTracking(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'Không tìm thấy thông tin vận chuyển cho đơn $shipmentId');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<ShipmentTrackingModel> syncTracking(String shipmentId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.shipmentSync(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'Đồng bộ hành trình vận chuyển thất bại');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<TamperSealModel?> verifyTamperSeal(String sealId) async {
    final cleanId = sealId.trim();
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.inspectionSealLookup(cleanId),
    );
    if (response.data == null) {
      throw AppException(message: 'Không tìm thấy thông tin tem niêm phong $cleanId');
    }
    final data = response.data!['data'] ?? response.data!;
    return TamperSealModel.fromJson(data as Map<String, dynamic>);
  }
}
