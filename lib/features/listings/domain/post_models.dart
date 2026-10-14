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
