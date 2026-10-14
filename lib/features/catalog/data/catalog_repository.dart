import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/catalog_models.dart';

class CatalogRepository {
  final ApiClient client;

  CatalogRepository({required this.client});

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await client.get<dynamic>(ApiEndpoints.categories).timeout(const Duration(seconds: 2));
      final data = response.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      }

      if (list.isNotEmpty) {
        return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback khi offline / backend chưa kết nối DB
    }

    return _mockCategories;
  }

  Future<List<ItemModel>> getItemsByCategory(String categoryId) async {
    try {
      final response = await client.get<dynamic>(ApiEndpoints.itemsByCategory(categoryId)).timeout(const Duration(seconds: 2));
      final data = response.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      }

      if (list.isNotEmpty) {
        return list.map((i) => ItemModel.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback
    }

    return _mockItems[categoryId] ?? _mockItems['cat-refrigerator'] ?? [];
  }

  static const List<CategoryModel> _mockCategories = [
    CategoryModel(id: 'cat-refrigerator', name: 'Tủ lạnh & Tủ đông', code: 'REFRIGERATOR'),
    CategoryModel(id: 'cat-washer', name: 'Máy giặt & Máy sấy', code: 'WASHER_DRYER'),
    CategoryModel(id: 'cat-ac', name: 'Điều hòa & Máy lạnh', code: 'AIR_CONDITIONER'),
    CategoryModel(id: 'cat-microwave', name: 'Lò vi sóng & Lò nướng', code: 'MICROWAVE'),
    CategoryModel(id: 'cat-cooker', name: 'Nồi cơm & Nồi áp suất', code: 'RICE_COOKER'),
    CategoryModel(id: 'cat-fryer', name: 'Nồi chiên không dầu', code: 'AIR_FRYER'),
    CategoryModel(id: 'cat-purifier', name: 'Máy lọc nước & Lọc không khí', code: 'AIR_PURIFIER'),
    CategoryModel(id: 'cat-vacuum', name: 'Máy hút bụi & Robot lau nhà', code: 'VACUUM_CLEANER'),
  ];

  static const Map<String, List<ItemModel>> _mockItems = {
    'cat-refrigerator': [
      ItemModel(id: 'item-ref-1', categoryId: 'cat-refrigerator', name: 'Tủ lạnh Inverter 2 cánh'),
      ItemModel(id: 'item-ref-2', categoryId: 'cat-refrigerator', name: 'Tủ lạnh Side-by-Side'),
      ItemModel(id: 'item-ref-3', categoryId: 'cat-refrigerator', name: 'Tủ lạnh Mini / Độc lập'),
      ItemModel(id: 'item-ref-4', categoryId: 'cat-refrigerator', name: 'Tủ đông mini đứng'),
    ],
    'cat-washer': [
      ItemModel(id: 'item-wash-1', categoryId: 'cat-washer', name: 'Máy giặt cửa ngang (Inverter)'),
      ItemModel(id: 'item-wash-2', categoryId: 'cat-washer', name: 'Máy giặt cửa trên'),
      ItemModel(id: 'item-wash-3', categoryId: 'cat-washer', name: 'Máy giặt sấy kết hợp'),
    ],
    'cat-ac': [
      ItemModel(id: 'item-ac-1', categoryId: 'cat-ac', name: 'Máy lạnh treo tường 1 HP - 1.5 HP'),
      ItemModel(id: 'item-ac-2', categoryId: 'cat-ac', name: 'Máy lạnh Inverter 2 HP'),
    ],
    'cat-fryer': [
      ItemModel(id: 'item-fry-1', categoryId: 'cat-fryer', name: 'Nồi chiên không dầu 4L - 6L'),
      ItemModel(id: 'item-fry-2', categoryId: 'cat-fryer', name: 'Nồi chiên không dầu điện tử có kính'),
    ],
  };
}
