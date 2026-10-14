class CreditBalanceModel {
  final int postCredits;
  final int valuationCredits;
  final int chatCredits;

  const CreditBalanceModel({
    this.postCredits = 0,
    this.valuationCredits = 0,
    this.chatCredits = 0,
  });

  factory CreditBalanceModel.fromJson(Map<String, dynamic> json) {
    return CreditBalanceModel(
      postCredits: (json['postCredits'] as num?)?.toInt() ?? 0,
      valuationCredits: (json['valuationCredits'] as num?)?.toInt() ?? 0,
      chatCredits: (json['chatCredits'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'postCredits': postCredits,
    'valuationCredits': valuationCredits,
    'chatCredits': chatCredits,
  };
}

class CreditPricingRuleModel {
  final String creditType; // 'LISTING' | 'VALUATION'
  final double unitPrice;
  final String currency;
  final bool active;

  const CreditPricingRuleModel({
    required this.creditType,
    required this.unitPrice,
    this.currency = 'VND',
    this.active = true,
  });

  factory CreditPricingRuleModel.fromJson(Map<String, dynamic> json) {
    return CreditPricingRuleModel(
      creditType: json['creditType'] ?? 'LISTING',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'VND',
      active: json['active'] as bool? ?? true,
    );
  }
}

class CreditDiscountTierModel {
  final String id;
  final int minQuantity;
  final int? maxQuantity;
  final double discountRate; // e.g. 0.1 for 10%
  final bool active;

  const CreditDiscountTierModel({
    required this.id,
    required this.minQuantity,
    this.maxQuantity,
    required this.discountRate,
    this.active = true,
  });

  factory CreditDiscountTierModel.fromJson(Map<String, dynamic> json) {
    return CreditDiscountTierModel(
      id: json['id']?.toString() ?? '',
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 0,
      maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] as bool? ?? true,
    );
  }

  int get discountPercent => (discountRate * 100).round();
}

class CreditQuoteModel {
  final int listingQuantity;
  final int valuationQuantity;
  final double listingUnitPrice;
  final double valuationUnitPrice;
  final double discountRate;
  final double subtotal;
  final double discountAmount;
  final double finalFee;
  final String currency;

  const CreditQuoteModel({
    this.listingQuantity = 0,
    this.valuationQuantity = 0,
    this.listingUnitPrice = 10000,
    this.valuationUnitPrice = 5000,
    this.discountRate = 0.0,
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.finalFee = 0.0,
    this.currency = 'VND',
  });

  factory CreditQuoteModel.fromJson(Map<String, dynamic> json) {
    return CreditQuoteModel(
      listingQuantity: (json['listingQuantity'] as num?)?.toInt() ?? 0,
      valuationQuantity: (json['valuationQuantity'] as num?)?.toInt() ?? 0,
      listingUnitPrice: (json['listingUnitPrice'] as num?)?.toDouble() ?? 10000.0,
      valuationUnitPrice: (json['valuationUnitPrice'] as num?)?.toDouble() ?? 5000.0,
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalFee: (json['finalFee'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'VND',
    );
  }
}

class CreditPurchaseModel {
  final String id;
  final String status; // PENDING, PAID, FAILED, EXPIRED
  final CreditQuoteModel snapshot;
  final String? paymentProvider;
  final String? createdAt;
  final String? paidAt;

  const CreditPurchaseModel({
    required this.id,
    required this.status,
    required this.snapshot,
    this.paymentProvider,
    this.createdAt,
    this.paidAt,
  });

  factory CreditPurchaseModel.fromJson(Map<String, dynamic> json) {
    return CreditPurchaseModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'PENDING',
      snapshot: json['snapshot'] != null
          ? CreditQuoteModel.fromJson(json['snapshot'] as Map<String, dynamic>)
          : const CreditQuoteModel(),
      paymentProvider: json['paymentProvider'],
      createdAt: json['createdAt'],
      paidAt: json['paidAt'],
    );
  }

  bool get isPaid => status.toUpperCase() == 'PAID';
}

class CreditLedgerItemModel {
  final String id;
  final String creditType; // 'LISTING' | 'VALUATION'
  final String entryType; // PURCHASE, USAGE, REFUND, BONUS
  final int quantityDelta;
  final int balanceAfter;
  final String createdAt;

  const CreditLedgerItemModel({
    required this.id,
    required this.creditType,
    required this.entryType,
    required this.quantityDelta,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory CreditLedgerItemModel.fromJson(Map<String, dynamic> json) {
    return CreditLedgerItemModel(
      id: json['id']?.toString() ?? '',
      creditType: json['creditType'] ?? 'LISTING',
      entryType: json['entryType'] ?? '',
      quantityDelta: (json['quantityDelta'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isPositive => quantityDelta > 0;

  String get entryTypeLabel {
    switch (entryType.toUpperCase()) {
      case 'PURCHASE':
        return 'Nạp gói tín dụng';
      case 'USAGE':
      case 'USE':
        return 'Sử dụng dịch vụ';
      case 'REFUND':
        return 'Hoàn trả lượt';
      case 'BONUS':
        return 'Thưởng đăng ký';
      default:
        return entryType;
    }
  }
}
