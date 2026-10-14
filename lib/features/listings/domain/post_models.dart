enum ApplianceCondition {
  likeNew('LIKE_NEW', 'Mới 99% (Rất ít dùng, đầy đủ phụ kiện)', 'Ngoại hình sáng đẹp như mới, tem niêm phong còn nguyên.'),
  usedGood('USED_GOOD', 'Tốt 90-95% (Có xước nhẹ, hoạt động tốt)', 'Có vài vết xước nhỏ trong quá trình sử dụng, động cơ êm ái.'),
  usedFair('USED_FAIR', 'Khá 80-85% (Đã dùng nhiều, chức năng ổn)', 'Ngoại hình ngả màu theo thời gian nhưng máy chạy bền bỉ.');

  final String code;
  final String label;
  final String description;

  const ApplianceCondition(this.code, this.label, this.description);

  static ApplianceCondition fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'LIKE_NEW':
        return ApplianceCondition.likeNew;
      case 'USED_FAIR':
        return ApplianceCondition.usedFair;
      case 'USED_GOOD':
      default:
        return ApplianceCondition.usedGood;
    }
  }
}

class PostInitResponseModel {
  final String postId;
  final String aiSessionId;
  final String initialMessage;
  final List<String> suggestedQuestions;
  final String? visualReport;

  const PostInitResponseModel({
    required this.postId,
    required this.aiSessionId,
    required this.initialMessage,
    this.suggestedQuestions = const [],
    this.visualReport,
  });

  factory PostInitResponseModel.fromJson(Map<String, dynamic> json) {
    List<String> questions = [];
    if (json['suggestedQuestions'] is List) {
      questions = (json['suggestedQuestions'] as List).map((q) => q.toString()).toList();
    }

    return PostInitResponseModel(
      postId: json['postId']?.toString() ?? '',
      aiSessionId: json['aiSessionId']?.toString() ?? '',
      initialMessage: json['initialMessage'] ?? '',
      suggestedQuestions: questions,
      visualReport: json['visualReport'],
    );
  }
}

class AiChatMessageModel {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;

  const AiChatMessageModel({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
  });
}

class AiPriceEstimationModel {
  final double estimatedPrice;
  final double priceMin;
  final double priceMax;
  final double confidence;
  final String reasoning;
  final String currency;

  const AiPriceEstimationModel({
    this.estimatedPrice = 0.0,
    this.priceMin = 0.0,
    this.priceMax = 0.0,
    this.confidence = 0.0,
    this.reasoning = '',
    this.currency = 'VND',
  });

  factory AiPriceEstimationModel.fromJson(Map<String, dynamic> json) {
    return AiPriceEstimationModel(
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      priceMin: (json['priceMin'] as num?)?.toDouble() ?? 0.0,
      priceMax: (json['priceMax'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      currency: json['currency'] ?? 'VND',
    );
  }
}

class ShippingPackageModel {
  final int weightGrams;
  final int lengthCm;
  final int widthCm;
  final int heightCm;

  const ShippingPackageModel({
    this.weightGrams = 1000,
    this.lengthCm = 20,
    this.widthCm = 20,
    this.heightCm = 20,
  });

  factory ShippingPackageModel.fromJson(Map<String, dynamic> json) {
    return ShippingPackageModel(
      weightGrams: (json['weightGrams'] as num?)?.toInt() ?? 1000,
      lengthCm: (json['lengthCm'] as num?)?.toInt() ?? 20,
      widthCm: (json['widthCm'] as num?)?.toInt() ?? 20,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageWeightGrams': weightGrams,
    'packageLengthCm': lengthCm,
    'packageWidthCm': widthCm,
    'packageHeightCm': heightCm,
  };
}

class PostSubmitResponseModel {
  final String id;
  final String status;
  final String? message;

  const PostSubmitResponseModel({
    required this.id,
    required this.status,
    this.message,
  });

  factory PostSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return PostSubmitResponseModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'ACTIVE',
      message: json['message'],
    );
  }
}

enum ListingStatus {
  draft('DRAFT', 'Bản nháp'),
  pending('PENDING', 'Chờ duyệt'),
  active('ACTIVE', 'Đang bán'),
  reserved('RESERVED', 'Đang giữ chỗ'),
  sold('SOLD', 'Đã bán'),
  rejected('REJECTED', 'Bị từ chối'),
  hidden('HIDDEN', 'Đã ẩn');

  final String code;
  final String label;

  const ListingStatus(this.code, this.label);

  static ListingStatus fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'DRAFT':
        return ListingStatus.draft;
      case 'PENDING':
        return ListingStatus.pending;
      case 'RESERVED':
        return ListingStatus.reserved;
      case 'SOLD':
        return ListingStatus.sold;
      case 'REJECTED':
        return ListingStatus.rejected;
      case 'HIDDEN':
        return ListingStatus.hidden;
      case 'ACTIVE':
      default:
        return ListingStatus.active;
    }
  }
}

class SellerListingItemModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final ApplianceCondition itemCondition;
  final List<String> imageUrls;
  final ListingStatus status;
  final String? rejectionReason;
  final bool listingCreditCharged;
  final double? aiSuggestedPrice;
  final int? shippingWeight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerListingItemModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    this.itemCondition = ApplianceCondition.usedGood,
    this.imageUrls = const [],
    this.status = ListingStatus.active,
    this.rejectionReason,
    this.listingCreditCharged = false,
    this.aiSuggestedPrice,
    this.shippingWeight,
    this.createdAt,
    this.updatedAt,
  });

  String get primaryImageUrl {
    if (imageUrls.isNotEmpty && imageUrls.first.isNotEmpty) {
      return imageUrls.first;
    }
    return 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=500&q=80';
  }

  factory SellerListingItemModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['imageUrls'] is List) {
      images = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is List) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    }

    return SellerListingItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Thiết bị gia dụng',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      itemCondition: ApplianceCondition.fromCode(json['itemCondition']?.toString()),
      imageUrls: images,
      status: ListingStatus.fromCode(json['status']?.toString()),
      rejectionReason: json['rejectionReason']?.toString(),
      listingCreditCharged: json['listingCreditCharged'] == true,
      aiSuggestedPrice: (json['aiSuggestedPrice'] as num?)?.toDouble(),
      shippingWeight: (json['shippingWeight'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  SellerListingItemModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    ApplianceCondition? itemCondition,
    List<String>? imageUrls,
    ListingStatus? status,
    String? rejectionReason,
    bool? listingCreditCharged,
    double? aiSuggestedPrice,
    int? shippingWeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerListingItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      itemCondition: itemCondition ?? this.itemCondition,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      listingCreditCharged: listingCreditCharged ?? this.listingCreditCharged,
      aiSuggestedPrice: aiSuggestedPrice ?? this.aiSuggestedPrice,
      shippingWeight: shippingWeight ?? this.shippingWeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

