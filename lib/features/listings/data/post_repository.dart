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
}
