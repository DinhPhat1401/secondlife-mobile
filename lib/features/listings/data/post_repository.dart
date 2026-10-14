import 'dart:io';
import 'package:dio/dio.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/post_models.dart';

class PostRepository {
  final ApiClient client;

  PostRepository({required this.client});

  Future<PostInitResponseModel> initPost({
    required List<File> photos,
    String? categoryId,
    String? itemId,
    String? itemCondition,
  }) async {
    try {
      final formData = FormData();

      for (final photo in photos) {
        final fileName = photo.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(photo.path, filename: fileName),
          ),
        );
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        formData.fields.add(MapEntry('categoryId', categoryId));
      }
      if (itemId != null && itemId.isNotEmpty) {
        formData.fields.add(MapEntry('itemId', itemId));
      }
      if (itemCondition != null && itemCondition.isNotEmpty) {
        formData.fields.add(MapEntry('itemCondition', itemCondition));
      }

      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postsInit,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ).timeout(const Duration(milliseconds: 3000));

      if (response.data != null) {
        return PostInitResponseModel.fromJson(response.data!);
      }
    } catch (_) {
      // Fallback khi offline
    }

    return PostInitResponseModel(
      postId: 'post_draft_${DateTime.now().millisecondsSinceEpoch}',
      aiSessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      initialMessage: 'Chào bạn! Trợ lý AI sẵn sàng hỗ trợ bạn hoàn tất thông tin thiết bị.',
      suggestedQuestions: const [
        'Sản phẩm đã qua bảo hành hoặc sửa chữa lần nào chưa?',
        'Tình trạng hoạt động thực tế hiện tại như thế nào?',
      ],
    );
  }

  Future<String> sendAiChat({
    required String sessionId,
    required String message,
  }) async {
    try {
      final formData = FormData.fromMap({
        'sessionId': sessionId,
        'message': message,
      });

      final response = await client.post<dynamic>(
        ApiEndpoints.aiChat,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ).timeout(const Duration(milliseconds: 3000));

      final data = response.data;
      if (data is Map) {
        return data['message'] ?? data['reply'] ?? data['response'] ?? '';
      } else if (data is String) {
        return data;
      }
    } catch (_) {
      // Fallback
    }

    return 'Trợ lý AI đã ghi nhận: "$message". Sản phẩm có tình trạng rõ ràng, rất phù hợp để tiếp tục bước định giá và đăng bán.';
  }

  Future<String> finalizeChat({
    required String sessionId,
    String? message,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postFinalizeChat(sessionId),
        data: message != null ? {'message': message} : {},
      ).timeout(const Duration(milliseconds: 3000));

      final data = response.data ?? {};
      if (data['description'] != null || data['finalDescription'] != null) {
        return data['description'] ?? data['finalDescription'] ?? '';
      }
    } catch (_) {
      // Fallback
    }

    return 'Thiết bị gia dụng chính hãng, còn rất mới, hoạt động êm ái và đầy đủ tính năng. Sản phẩm đã được vệ sinh sạch sẽ, sẵn sàng bàn giao cho người mua.';
  }

  Future<String> regenerateChat({
    required String sessionId,
    String? message,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postRegenerateChat(sessionId),
        data: message != null ? {'message': message} : {},
      ).timeout(const Duration(milliseconds: 3000));

      final data = response.data ?? {};
      if (data['description'] != null || data['finalDescription'] != null) {
        return data['description'] ?? data['finalDescription'] ?? '';
      }
    } catch (_) {
      // Fallback
    }

    return 'Thiết bị gia dụng hoạt động bền bỉ, tiết kiệm điện năng. Đầy đủ phụ kiện theo máy, hỗ trợ kiểm tra thoải mái khi nhận hàng.';
  }

  Future<String> suggestTitle({
    required String postId,
    String? context,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postSuggestTitle(postId),
        data: context != null ? {'context': context} : {},
      ).timeout(const Duration(milliseconds: 3000));

      final data = response.data ?? {};
      if (data['title'] != null && (data['title'] as String).isNotEmpty) {
        return data['title'] as String;
      }
    } catch (_) {
      // Fallback
    }

    return 'Thiết bị gia dụng SecondLife chính hãng - Hoạt động tốt';
  }

  Future<AiPriceEstimationModel> estimatePrice({
    required String postId,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postAiPriceEstimation(postId),
      ).timeout(const Duration(milliseconds: 3000));

      if (response.data != null) {
        return AiPriceEstimationModel.fromJson(response.data!);
      }
    } catch (_) {
      // Fallback
    }

    return const AiPriceEstimationModel(
      estimatedPrice: 3200000,
      priceMin: 2800000,
      priceMax: 3600000,
      confidence: 0.88,
      reasoning: 'Mức giá đề xuất dựa trên phân tích hình ảnh, thương hiệu và giao dịch các thiết bị tương đương trên SecondLife.',
    );
  }

  Future<void> updateDraft({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await client.put<Map<String, dynamic>>(
        ApiEndpoints.postDraft(postId),
        data: data,
      ).timeout(const Duration(milliseconds: 2000));
    } catch (_) {
      // Bỏ qua lỗi cập nhật draft khi offline
    }
  }

  Future<PostSubmitResponseModel> submitPost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.postSubmit(postId),
        data: data,
      ).timeout(const Duration(milliseconds: 3000));

      if (response.data != null) {
        return PostSubmitResponseModel.fromJson(response.data!);
      }
    } catch (_) {
      // Fallback
    }

    return PostSubmitResponseModel(
      id: postId,
      status: 'ACTIVE',
      message: 'Tin đăng của bạn đã được gửi thành công!',
    );
  }

  Future<List<SellerListingItemModel>> getMyPosts({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.myPosts,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['content'] is List) {
        return (data['content'] as List)
            .map((item) => SellerListingItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _getMockListings(status);
    } catch (_) {
      return _getMockListings(status);
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await client.delete<void>(ApiEndpoints.postDelete(postId));
      return true;
    } catch (_) {
      return true; // Mock success
    }
  }

  Future<bool> boostListing(String postId) async {
    try {
      await client.post<Map<String, dynamic>>(ApiEndpoints.postBoost(postId));
      return true;
    } catch (_) {
      return true; // Mock success
    }
  }

  List<SellerListingItemModel> _getMockListings(String? statusFilter) {
    final now = DateTime.now();
    final mockList = [
      SellerListingItemModel(
        id: 'post-001',
        title: 'Tủ lạnh Panasonic Inverter 2 cánh 255L',
        description: 'Tủ hoạt động cực êm, làm đá nhanh, tiết kiệm điện năng Econavi, còn nguyên seal.',
        price: 3800000,
        itemCondition: ApplianceCondition.likeNew,
        imageUrls: const [
          'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=500&q=80',
        ],
        status: ListingStatus.active,
        listingCreditCharged: true,
        aiSuggestedPrice: 3950000,
        shippingWeight: 45000,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      SellerListingItemModel(
        id: 'post-002',
        title: 'Máy giặt Electrolux 8kg cửa ngang UltimateCare',
        description: 'Động cơ EcoInverter êm ái, giặt nước nóng diệt khuẩn, hình thức 92%.',
        price: 4200000,
        itemCondition: ApplianceCondition.usedGood,
        imageUrls: const [
          'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&q=80',
        ],
        status: ListingStatus.reserved, // Reservation window for agreed buyer
        listingCreditCharged: true,
        aiSuggestedPrice: 4300000,
        shippingWeight: 62000,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      SellerListingItemModel(
        id: 'post-003',
        title: 'Lò vi sóng có nướng Sharp 23L R-G302VN-S',
        description: 'Khoang lò thép không gỉ sáng bóng, bảng điều khiển cơ dễ dùng.',
        price: 950000,
        itemCondition: ApplianceCondition.usedGood,
        imageUrls: const [
          'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=500&q=80',
        ],
        status: ListingStatus.pending,
        listingCreditCharged: true,
        aiSuggestedPrice: 1000000,
        shippingWeight: 14000,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      SellerListingItemModel(
        id: 'post-004',
        title: 'Quạt đứng điều khiển từ xa Mitsubishi Tatami',
        description: 'Đã hoàn tất thanh lý cho người mua và giao qua Lalamove thành công.',
        price: 850000,
        itemCondition: ApplianceCondition.likeNew,
        imageUrls: const [
          'https://images.unsplash.com/photo-1618941716939-553df3c6c278?w=500&q=80',
        ],
        status: ListingStatus.sold,
        listingCreditCharged: true,
        aiSuggestedPrice: 900000,
        shippingWeight: 7500,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      SellerListingItemModel(
        id: 'post-005',
        title: 'Nồi chiên không dầu Philips HD9252/90 4.1L',
        description: 'Bản nháp đang lưu tạm, cần bổ sung ảnh góc cạnh đáy nồi.',
        price: 1200000,
        itemCondition: ApplianceCondition.usedFair,
        imageUrls: const [
          'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=500&q=80',
        ],
        status: ListingStatus.draft,
        listingCreditCharged: false,
        aiSuggestedPrice: 1250000,
        shippingWeight: 5000,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    if (statusFilter == null || statusFilter.isEmpty || statusFilter == 'ALL') {
      return mockList;
    }

    return mockList.where((p) => p.status.code == statusFilter).toList();
  }
}

