class PickupAddressModel {
  final String name;
  final String phone;
  final String? address;
  final double latitude;
  final double longitude;

  PickupAddressModel({
    required this.name,
    required this.phone,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  factory PickupAddressModel.fromJson(Map<String, dynamic> json) {
    return PickupAddressModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (address != null) 'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class SellerOnboardingModel {
  final String? shopName;
  final String? email;
  final String? phone;
  final PickupAddressModel? pickupAddress;
  final bool emailVerified;
  final bool canStartEkyc;
  final String nextStep; // SHOP_INFORMATION, EMAIL_VERIFICATION, EKYC, COMPLETED

  SellerOnboardingModel({
    this.shopName,
    this.email,
    this.phone,
    this.pickupAddress,
    required this.emailVerified,
    required this.canStartEkyc,
    required this.nextStep,
  });

  factory SellerOnboardingModel.fromJson(Map<String, dynamic> json) {
    return SellerOnboardingModel(
      shopName: json['shopName'],
      email: json['email'],
      phone: json['phone'],
      pickupAddress: json['pickupAddress'] != null
          ? PickupAddressModel.fromJson(json['pickupAddress'] as Map<String, dynamic>)
          : null,
      emailVerified: json['emailVerified'] as bool? ?? false,
      canStartEkyc: json['canStartEkyc'] as bool? ?? false,
      nextStep: json['nextStep'] ?? 'SHOP_INFORMATION',
    );
  }

  Map<String, dynamic> toJson() => {
    'shopName': shopName,
    'email': email,
    'phone': phone,
    if (pickupAddress != null) 'pickupAddress': pickupAddress!.toJson(),
  };
}

class ReverseGeocodeResult {
  final String address;
  final String? city;
  final double latitude;
  final double longitude;

  ReverseGeocodeResult({
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      address: json['address'] ?? '',
      city: json['city'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
