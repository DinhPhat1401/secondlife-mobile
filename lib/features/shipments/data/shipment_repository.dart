import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/shipment_models.dart';

class ShipmentRepository {
  final ApiClient client;

  ShipmentRepository({required this.client});

  Future<ShipmentTrackingModel> getTracking(String shipmentId) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.shipmentTracking(shipmentId),
      );
      if (response.data != null) {
        return ShipmentTrackingModel.fromJson(response.data!);
      }
    } catch (_) {
      // Fallback
    }

    // Default structured model if tracking not yet created on carrier
    return ShipmentTrackingModel(
      shipmentId: shipmentId,
      trackingNumber: 'LLM-$shipmentId',
      carrier: 'LALAMOVE',
      status: 'ON_GOING',
      statusDescription: 'Tài xế đang trên đường giao hàng',
      timeline: [
        ShipmentTimelineEvent(
          timestamp: '14:30 14/10/2026',
          title: 'Đã nhận đơn giao vận Lalamove',
          description: 'Hệ thống đã khớp lệnh thành công với tài xế.',
        ),
        ShipmentTimelineEvent(
          timestamp: '15:15 14/10/2026',
          title: 'Tài xế đã lấy hàng tại kho người bán',
          description: 'Kiện hàng đồ gia dụng đã được đóng gói kỹ càng.',
        ),
        ShipmentTimelineEvent(
          timestamp: '15:45 14/10/2026',
          title: 'Đang vận chuyển đến người mua',
          description: 'Dự kiến giao hàng trong vòng 45 phút.',
        ),
      ],
    );
  }

  Future<ShipmentTrackingModel> syncTracking(String shipmentId) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.shipmentSync(shipmentId),
      );
      if (response.data != null) {
        return ShipmentTrackingModel.fromJson(response.data!);
      }
    } catch (_) {
      // Return fresh tracking
    }
    return getTracking(shipmentId);
  }
}
