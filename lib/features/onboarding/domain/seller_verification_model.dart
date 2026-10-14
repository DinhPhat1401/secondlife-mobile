enum VerificationStatus {
  submitted,
  ekycPending,
  needsReview,
  approved,
  resubmitRequired,
  rejected,
  unknown;

  static VerificationStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUBMITTED':
        return VerificationStatus.submitted;
      case 'EKYC_PENDING':
        return VerificationStatus.ekycPending;
      case 'NEEDS_REVIEW':
        return VerificationStatus.needsReview;
      case 'APPROVED':
        return VerificationStatus.approved;
      case 'RESUBMIT_REQUIRED':
        return VerificationStatus.resubmitRequired;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case VerificationStatus.submitted:
        return 'Đã nộp hồ sơ';
      case VerificationStatus.ekycPending:
        return 'Đang quét eKYC';
      case VerificationStatus.needsReview:
        return 'Chờ xét duyệt thủ công';
      case VerificationStatus.approved:
        return 'Đã duyệt thành công';
      case VerificationStatus.resubmitRequired:
        return 'Cần nộp lại ảnh';
      case VerificationStatus.rejected:
        return 'Hồ sơ bị từ chối';
      case VerificationStatus.unknown:
        return 'Chưa xác định';
    }
  }
}

class SellerVerificationModel {
  final String id;
  final String userId;
  final String? shopName;
  final String verificationType;
  final String documentNumber;
  final String? documentNumberMasked;
  final String documentFrontUrl;
  final String documentBackUrl;
  final String? selfieUrl;
  final VerificationStatus status;
  final String? rejectionReason;
  final String? reasonCodeDescription;
  final String? submittedAt;
  final int resubmissionCount;

  SellerVerificationModel({
    required this.id,
    required this.userId,
    this.shopName,
    required this.verificationType,
    required this.documentNumber,
    this.documentNumberMasked,
    required this.documentFrontUrl,
    required this.documentBackUrl,
    this.selfieUrl,
    required this.status,
    this.rejectionReason,
    this.reasonCodeDescription,
    this.submittedAt,
    this.resubmissionCount = 0,
  });

  factory SellerVerificationModel.fromJson(Map<String, dynamic> json) {
    return SellerVerificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      shopName: json['shopName'],
      verificationType: json['verificationType'] ?? 'CITIZEN_ID',
      documentNumber: json['documentNumber'] ?? '',
      documentNumberMasked: json['documentNumberMasked'],
      documentFrontUrl: json['documentFrontUrl'] ?? '',
      documentBackUrl: json['documentBackUrl'] ?? '',
      selfieUrl: json['selfieUrl'],
      status: VerificationStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejectionReason'] ?? json['reasonCodeDescription'],
      reasonCodeDescription: json['reasonCodeDescription'],
      submittedAt: json['submittedAt'],
      resubmissionCount: (json['resubmissionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
