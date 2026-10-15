enum OrderStatus {
  pending('PENDING', 'Chờ xác nhận'),
  confirmed('CONFIRMED', 'Đã xác nhận'),
  shipping('SHIPPING', 'Đang vận chuyển'),
  delivered('DELIVERED', 'Đã giao thành công'),
  cancelled('CANCELLED', 'Đã hủy'),
  unknown('UNKNOWN', 'Không xác định');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'SHIPPING':
      case 'SHIPPED':
        return OrderStatus.shipping;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }
}

class DeliveryAddressModel {
  final String name;
  final String phone;
  final String address;
  final String? wardName;
  final String? provinceName;

  const DeliveryAddressModel({
    required this.name,
    required this.phone,
    required this.address,
    this.wardName,
    this.provinceName,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      name: json['name'] ?? json['recipientName'] ?? '',
      phone: json['phone'] ?? json['recipientPhone'] ?? '',
      address: json['address'] ?? json['detailAddress'] ?? '',
      wardName: json['wardName'],
      provinceName: json['provinceName'],
    );
  }

  String get fullAddressText {
    final parts = [address, wardName, provinceName].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class SellerOrderModel {
  final String id;
  final String? orderNumber;
  final String? postId;
  final String postTitle;
  final String? postThumbnail;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final DeliveryAddressModel? deliveryAddress;
  final double itemPrice;
  final double shippingFee;
  final double platformFee;
  final double netPayout;
  final OrderStatus status;
  final bool hasInspection;
  final String? shipmentId;
  final String? createdAt;
  final String? updatedAt;

  const SellerOrderModel({
    required this.id,
    this.orderNumber,
    this.postId,
    required this.postTitle,
    this.postThumbnail,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.deliveryAddress,
    required this.itemPrice,
    this.shippingFee = 0.0,
    this.platformFee = 0.0,
    required this.netPayout,
    required this.status,
    this.hasInspection = false,
    this.shipmentId,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    final itemPrice = (json['finalPrice'] as num?)?.toDouble() ??
        (json['itemPrice'] as num?)?.toDouble() ??
        (json['totalPaid'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;
    final platformFee = (json['platformFee'] as num?)?.toDouble() ?? (json['commissionFee'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (json['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final netPayout = (json['netPayout'] as num?)?.toDouble() ?? (itemPrice - platformFee);

    return SellerOrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] ?? json['code'],
      postId: json['postId']?.toString(),
      postTitle: json['postTitle'] ?? json['productTitle'] ?? json['listingTitle'] ?? 'Thiết bị gia dụng',
      postThumbnail: json['postThumbnail'] ?? json['productImageUrl'] ?? json['imageUrl'],
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName'] ?? json['recipientName'] ?? 'Người mua',
      buyerPhone: json['buyerPhone'] ?? json['recipientPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddressModel.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      itemPrice: itemPrice,
      shippingFee: shippingFee,
      platformFee: platformFee,
      netPayout: netPayout,
      status: OrderStatus.fromString(json['status'] as String?),
      hasInspection: json['hasInspection'] as bool? ?? false,
      shipmentId: json['shipmentId']?.toString(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }
}
