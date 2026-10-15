import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import '../domain/post_models.dart';

class PostRepository {
  final ApiClient client;

  PostRepository({required this.client});

  Future<PostInitResponseModel> initPost({
    required List<File> photos,
    String? categoryId,
    String? itemId,
    String? itemCondition,
    String? brand,
    String? model,
  }) async {
    final formData = FormData();

    for (final photo in photos) {
      final fileName = photo.path.split(Platform.pathSeparator).last;
      final ext = fileName.split('.').last.toLowerCase();
      final mimeSubType = (ext == 'png') ? 'png' : ((ext == 'webp') ? 'webp' : 'jpeg');
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            photo.path,
            filename: fileName,
            contentType: DioMediaType('image', mimeSubType),
          ),
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
    if (brand != null && brand.isNotEmpty) {
      formData.fields.add(MapEntry('brand', brand));
    }
    if (model != null && model.isNotEmpty) {
      formData.fields.add(MapEntry('model', model));
    }

    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postsInit,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.data == null) {
      throw AppException(message: 'Không nhận được dữ liệu khởi tạo tin đăng từ máy chủ');
    }
    final payload = response.data!['data'] ?? response.data!;
    return PostInitResponseModel.fromJson(payload as Map<String, dynamic>);
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
      final payload = data['data'] ?? data;
      final reply = payload['reply'] ?? payload['message'] ?? payload['response'] ?? '';
      return reply.toString();
    } else if (data is String) {
      return data;
    }
    throw AppException(message: 'Không nhận được phản hồi từ AI');
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
    final desc = data['description'] ?? data['finalDescription'] ?? data['data']?['description'];
    if (desc != null && desc.toString().isNotEmpty) {
      return desc.toString();
    }
    throw AppException(message: 'Không thể tổng hợp mô tả từ trợ lý AI');
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
    final desc = data['description'] ?? data['finalDescription'] ?? data['data']?['description'];
    if (desc != null && desc.toString().isNotEmpty) {
      return desc.toString();
    }
    throw AppException(message: 'Không thể tạo lại mô tả từ máy chủ');
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
    final title = data['title'] ?? data['data']?['title'];
    if (title != null && (title as String).isNotEmpty) {
      return title;
    }
    throw AppException(message: 'Không thể gợi ý tiêu đề từ máy chủ');
  }

  Future<AiPriceEstimationModel> estimatePrice({
    required String postId,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.postAiPriceEstimation(postId),
      data: {'requestId': const Uuid().v4()},
    );

    if (response.data == null) {
      throw AppException(message: 'Không nhận được kết quả định giá từ máy chủ');
    }
    final payload = response.data!['data'] ?? response.data!;
    return AiPriceEstimationModel.fromJson(payload as Map<String, dynamic>);
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

    if (response.data == null) {
      throw AppException(message: 'Gửi duyệt tin đăng thất bại');
    }
    final payload = response.data!['data'] ?? response.data!;
    return PostSubmitResponseModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<List<SellerListingItemModel>> getMyPosts({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
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
    List<dynamic> list = [];
    if (data != null) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['items'] is List) {
        list = data['items'] as List;
      }
    }
    return list
        .map((item) => SellerListingItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deletePost(String postId) async {
    await client.delete<void>(ApiEndpoints.postDelete(postId));
    return true;
  }

  Future<bool> boostListing(String postId) async {
    await client.post<Map<String, dynamic>>(ApiEndpoints.postBoost(postId));
    return true;
  }
}
