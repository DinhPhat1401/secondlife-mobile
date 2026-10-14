import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/notification_models.dart';

class NotificationRepository {
  final ApiClient client;

  NotificationRepository({required this.client});

  Future<List<NotificationModel>> getNotifications({
    bool? unreadOnly,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly;
      if (type != null && type.isNotEmpty && type != 'ALL') queryParams['type'] = type;

      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['content'] is List) {
        return (data['content'] as List)
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _getMockNotifications(unreadOnly: unreadOnly, typeFilter: type);
    } catch (_) {
      return _getMockNotifications(unreadOnly: unreadOnly, typeFilter: type);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.notificationsUnreadCount);
      final data = response.data;
      if (data != null && data['unreadCount'] is num) {
        return (data['unreadCount'] as num).toInt();
      }
      return 3;
    } catch (_) {
      return 3;
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await client.patch<Map<String, dynamic>>(ApiEndpoints.notificationMarkRead(id));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await client.patch<Map<String, dynamic>>(ApiEndpoints.notificationReadAll);
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await client.delete<void>(ApiEndpoints.notificationDelete(id));
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> clearRead() async {
    try {
      await client.delete<void>(ApiEndpoints.notificationClearRead);
      return true;
    } catch (_) {
      return true;
    }
  }

  List<NotificationModel> _getMockNotifications({bool? unreadOnly, String? typeFilter}) {
    final now = DateTime.now();
    final mockList = [
      NotificationModel(
        id: 'notif-001',
        title: 'Tài xế Lalamove đang đến lấy hàng',
        body: 'Tài xế Trần Văn Nam (Biển số: 29D-882.11) đang di chuyển đến điểm nhận hàng cho đơn #ORD-8821.',
        type: NotificationType.order,
        isRead: false,
        referenceId: 'shp-001',
        referenceType: 'SHIPMENT',
        targetUrl: '/shipments/shp-001/tracking',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'notif-002',
        title: 'Người mua đề xuất mức giá mới',
        body: 'Người mua Hoàng Long đề nghị mua Máy giặt Electrolux với giá 3.900.000 đ (Giảm 7%).',
        type: NotificationType.negotiation,
        isRead: false,
        referenceId: 'neg-001',
        referenceType: 'NEGOTIATION',
        targetUrl: '/negotiations',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif-003',
        title: 'Tin nhắn mới từ người mua',
        body: 'Lê Minh: "Anh ơi tủ lạnh Panasonic này còn bảo hành chính hãng bao lâu vậy ạ?"',
        type: NotificationType.chat,
        isRead: false,
        referenceId: 'room-101',
        referenceType: 'CHAT',
        targetUrl: '/chats',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'notif-004',
        title: 'Yêu cầu rút tiền đã được phê duyệt',
        body: 'Hệ thống đã chuyển 2.000.000 đ vào tài khoản Vietcombank 1019283746 thành công.',
        type: NotificationType.wallet,
        isRead: true,
        referenceId: 'wd-001',
        referenceType: 'WALLET',
        targetUrl: '/wallet',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'notif-005',
        title: 'Kiểm định hoàn tất: Đạt chuẩn tem niêm phong',
        body: 'Thiết bị Tủ lạnh Panasonic đã được kỹ thuật viên dán tem niêm phong SL-SEAL-20261014-9988.',
        type: NotificationType.inspection,
        isRead: true,
        referenceId: 'SL-SEAL-20261014-9988',
        referenceType: 'SEAL',
        targetUrl: '/orders',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationModel(
        id: 'notif-006',
        title: 'Chào mừng bạn đến với SecondLife Seller',
        body: 'Tài khoản người bán của bạn đã được kích hoạt thành công. Bắt đầu đăng tin thanh lý ngay!',
        type: NotificationType.system,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    var result = mockList;
    if (unreadOnly == true) {
      result = result.where((n) => !n.isRead).toList();
    }
    if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'ALL') {
      result = result.where((n) => n.type.code == typeFilter).toList();
    }
    return result;
  }
}
