import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/orders/domain/order_models.dart';
import 'package:secondlife_app_seller/features/shipments/domain/shipment_models.dart';
import 'package:secondlife_app_seller/features/negotiations/domain/negotiation_model.dart';
import 'package:secondlife_app_seller/features/chat/domain/chat_models.dart';

void main() {
  group('Sprint 4 - Orders Models Tests', () {
    test('Correctly maps OrderStatus string to enum', () {
      expect(OrderStatus.fromString('PENDING'), OrderStatus.pending);
      expect(OrderStatus.fromString('CONFIRMED'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('SHIPPED'), OrderStatus.shipping);
      expect(OrderStatus.fromString('SHIPPING'), OrderStatus.shipping);
      expect(OrderStatus.fromString('DELIVERED'), OrderStatus.delivered);
      expect(OrderStatus.fromString('CANCELLED'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('UNKNOWN'), OrderStatus.unknown);
    });

    test('Parses SellerOrderModel from JSON with delivery address', () {
      final json = {
        'id': 'ord-123',
        'postId': 'post-456',
        'postTitle': 'Tủ lạnh Panasonic 300L Inverter',
        'postImageUrl': 'https://images.example.com/fridge.jpg',
        'buyerId': 'usr-789',
        'buyerName': 'Nguyễn Văn A',
        'buyerPhone': '0901234567',
        'sellerId': 'seller-001',
        'totalAmount': 4500000.0,
        'shippingFee': 120000.0,
        'status': 'CONFIRMED',
        'shipmentId': 'ship-999',
        'deliveryAddress': {
          'name': 'Nguyễn Văn A',
          'phone': '0901234567',
          'address': '123 Nguyễn Văn Cừ',
          'wardName': 'Phường 4',
          'provinceName': 'TP. Hồ Chí Minh',
        },
        'createdAt': '2026-10-14T10:00:00Z',
      };

      final order = SellerOrderModel.fromJson(json);

      expect(order.id, 'ord-123');
      expect(order.postTitle, 'Tủ lạnh Panasonic 300L Inverter');
      expect(order.status, OrderStatus.confirmed);
      expect(order.itemPrice, 4500000.0);
      expect(order.shippingFee, 120000.0);
      expect(order.deliveryAddress, isNotNull);
      expect(order.deliveryAddress!.name, 'Nguyễn Văn A');
      expect(order.deliveryAddress!.fullAddressText,
          '123 Nguyễn Văn Cừ, Phường 4, TP. Hồ Chí Minh');
    });
  });

  group('Sprint 4 - Shipments & Lalamove Tracking Tests', () {
    test('Parses ShipmentTrackingModel and timeline events correctly', () {
      final json = {
        'shipmentId': 'ship-999',
        'trackingNumber': 'LLM-VN-20261014-88',
        'carrier': 'LALAMOVE',
        'status': 'ON_GOING',
        'statusDescription': 'Đang vận chuyển',
        'driverName': 'Trần Văn Tài',
        'driverPhone': '0912345678',
        'plateNumber': '59-X1 123.45',
        'estimatedDelivery': '14:30 14/10/2026',
        'timeline': [
          {
            'title': 'Đang điều phối tài xế Lalamove',
            'description': 'Hệ thống tìm kiếm tài xế gần nhất',
            'timestamp': '2026-10-14T09:00:00Z',
            'isCompleted': true,
          },
          {
            'title': 'Tài xế đã nhận hàng và đang di chuyển',
            'timestamp': '2026-10-14T09:45:00Z',
            'isCompleted': true,
          },
          {
            'title': 'Giao hàng thành công',
            'timestamp': '',
            'isCompleted': false,
          },
        ],
      };

      final tracking = ShipmentTrackingModel.fromJson(json);

      expect(tracking.shipmentId, 'ship-999');
      expect(tracking.trackingNumber, 'LLM-VN-20261014-88');
      expect(tracking.carrier, 'LALAMOVE');
      expect(tracking.driverName, 'Trần Văn Tài');
      expect(tracking.plateNumber, '59-X1 123.45');
      expect(tracking.timeline.length, 3);
      expect(tracking.timeline[0].isCompleted, isTrue);
      expect(tracking.timeline[2].isCompleted, isFalse);
    });
  });

  group('Sprint 4 - Price Negotiations Tests', () {
    test('Parses NegotiationModel and calculates discount percentage', () {
      final json = {
        'id': 'neg-101',
        'postId': 'post-202',
        'postTitle': 'Máy giặt Electrolux 9kg Inverter',
        'buyerName': 'Lê Thị Thu',
        'offeredPrice': 3200000.0,
        'originalPrice': 4000000.0,
        'status': 'PENDING',
        'productImageUrl': 'https://images.example.com/washer.jpg',
      };

      final neg = NegotiationModel.fromJson(json);

      expect(neg.id, 'neg-101');
      expect(neg.postTitle, 'Máy giặt Electrolux 9kg Inverter');
      expect(neg.buyerName, 'Lê Thị Thu');
      expect(neg.offeredPrice, 3200000.0);
      expect(neg.originalPrice, 4000000.0);
      expect(neg.isPending, isTrue);
      expect(neg.isAccepted, isFalse);
      // Discount = (4M - 3.2M) / 4M = 20%
      expect(neg.discountPercentage, closeTo(20.0, 0.01));
    });

    test('Handles negotiation status flags', () {
      const accepted = NegotiationModel(
        id: 'neg-1',
        postId: 'post-1',
        postTitle: 'Lò vi sóng',
        offeredPrice: 500000,
        status: 'ACCEPTED',
      );
      expect(accepted.isAccepted, isTrue);
      expect(accepted.isPending, isFalse);
    });
  });

  group('Sprint 4 - In-App Chat Models Tests', () {
    test('Parses ChatRoomModel from JSON', () {
      final json = {
        'id': 'room-01',
        'postId': 'post-11',
        'postTitle': 'Nồi cơm điện Cuckoo',
        'buyerId': 'buyer-99',
        'buyerName': 'Phạm Hoàng',
        'sellerId': 'seller-01',
        'sellerName': 'SecondLife Official',
        'lastMessage': 'Sản phẩm còn bảo hành không shop?',
      };

      final room = ChatRoomModel.fromJson(json);

      expect(room.id, 'room-01');
      expect(room.buyerName, 'Phạm Hoàng');
      expect(room.lastMessage, 'Sản phẩm còn bảo hành không shop?');
    });

    test('Parses regular message vs SYSTEM offer message correctly', () {
      const regularMsg = ChatMessageModel(
        id: 'msg-1',
        conversationId: 'room-01',
        senderId: 'buyer-99',
        messageContent: 'Chào shop, máy dùng được bao lâu rồi ạ?',
        sentAt: '2026-10-14T11:00:00Z',
      );

      expect(regularMsg.isSystem, isFalse);
      expect(regularMsg.isOffer, isFalse);
      expect(regularMsg.cleanText, 'Chào shop, máy dùng được bao lâu rồi ạ?');

      const systemOfferMsg = ChatMessageModel(
        id: 'msg-2',
        conversationId: 'room-01',
        senderId: 'SYSTEM',
        messageContent: 'SYSTEM: {"type":"OFFER","status":"PENDING","price":850000,"negotiationId":"neg-999"}',
        sentAt: '2026-10-14T11:05:00Z',
      );

      expect(systemOfferMsg.isSystem, isTrue);
      expect(systemOfferMsg.isOffer, isTrue);
      expect(systemOfferMsg.cleanText, 'Đề xuất giá mới: 850000 đ');
      expect(systemOfferMsg.offerPayload?['price'], 850000);
      expect(systemOfferMsg.offerPayload?['negotiationId'], 'neg-999');
    });
  });
}
