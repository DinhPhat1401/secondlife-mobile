import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class MediaRepository {
  final ApiClient client;

  MediaRepository({required this.client});

  /// Compress and upload an image to Cloudinary via Backend
  Future<String> uploadImage(File file, {String folder = 'seller-verifications'}) async {
    // Compress image before upload
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = '${splitted}_compressed.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 80,
      minWidth: 1200,
      minHeight: 1200,
    );

    final uploadFile = compressed != null ? File(compressed.path) : file;
    final fileName = uploadFile.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(uploadFile.path, filename: fileName),
      'folder': folder,
    });

    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.mediaUpload,
      data: formData,
    );

    final data = response.data;
    if (data != null && data['url'] != null) {
      return data['url'] as String;
    }

    throw Exception('Không nhận được URL ảnh sau khi tải lên');
  }
}
