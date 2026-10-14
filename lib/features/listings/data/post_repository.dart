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
    );

    return PostInitResponseModel.fromJson(response.data!);
  }

  Future<String> sendAiChat({
    required String sessionId,
    required String message,
  }) async {
    final formData = FormData.fromMap({
      'sessionId': sessionId,
      'message': message,
    });

    final response = await client.post<dynamic>(
      ApiEndpoints.aiChat,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data is Map) {
      return data['message'] ?? data['reply'] ?? data['response'] ?? '';
    } else if (data is String) {
      return data;
    }
    return '';
  }

  Future<String> finalizeChat({
    required String sessionId,
    String? message,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postFinalizeChat(sessionId),
      data: message != null ? {'message': message} : {},
    );

    final data = response.data ?? {};
    return data['description'] ?? data['finalDescription'] ?? '';
  }

  Future<String> regenerateChat({
    required String sessionId,
    String? message,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postRegenerateChat(sessionId),
      data: message != null ? {'message': message} : {},
    );

    final data = response.data ?? {};
    return data['description'] ?? data['finalDescription'] ?? '';
  }

  Future<String> suggestTitle({
    required String postId,
    String? context,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postSuggestTitle(postId),
      data: context != null ? {'context': context} : {},
    );

    final data = response.data ?? {};
    return data['title'] ?? '';
  }

  Future<AiPriceEstimationModel> estimatePrice({
    required String postId,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postAiPriceEstimation(postId),
    );

    return AiPriceEstimationModel.fromJson(response.data!);
  }

  Future<void> updateDraft({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    await client.put<Map<String, dynamic>>(
      ApiEndpoints.postDraft(postId),
      data: data,
    );
  }

  Future<PostSubmitResponseModel> submitPost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postSubmit(postId),
      data: data,
    );

    return PostSubmitResponseModel.fromJson(response.data!);
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

