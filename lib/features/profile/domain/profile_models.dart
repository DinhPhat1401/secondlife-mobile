class SellerProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatarUrl;
  final String accountStatus;
  final bool emailVerified;
  final bool isSeller;
  final String? province;
  final String? district;
  final String? ward;
  final String? streetAddress;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatarUrl = '',
    this.accountStatus = 'ACTIVE',
    this.emailVerified = true,
    this.isSeller = true,
    this.province,
    this.district,
    this.ward,
    this.streetAddress,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress {
    final parts = [streetAddress, ward, district, province]
        .where((s) => s != null && s.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Chưa thiết lập địa chỉ kho';
    return parts.join(', ');
  }

  String get displayAvatarUrl {
    if (avatarUrl.isNotEmpty) return avatarUrl;
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';
  }

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    final isSellerRole = roles is List && roles.any((r) => r.toString().contains('SELLER'));

    return SellerProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Người bán SecondLife',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      accountStatus: json['accountStatus']?.toString() ?? 'ACTIVE',
      emailVerified: json['emailVerified'] == true,
      isSeller: isSellerRole || json['isSeller'] == true,
      province: json['province']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      streetAddress: json['streetAddress']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  SellerProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? accountStatus,
    bool? emailVerified,
    bool? isSeller,
    String? province,
    String? district,
    String? ward,
    String? streetAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return SellerProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      emailVerified: emailVerified ?? this.emailVerified,
      isSeller: isSeller ?? this.isSeller,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      streetAddress: streetAddress ?? this.streetAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UpdateProfileRequestModel {
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String? province;
  final String? district;
  final String? ward;
  final String? streetAddress;
  final double? latitude;
  final double? longitude;

  const UpdateProfileRequestModel({
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.province,
    this.district,
    this.ward,
    this.streetAddress,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
    };
    if (avatarUrl != null) map['avatarUrl'] = avatarUrl;
    if (province != null) map['province'] = province;
    if (district != null) map['district'] = district;
    if (ward != null) map['ward'] = ward;
    if (streetAddress != null) map['streetAddress'] = streetAddress;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    return map;
  }
}
