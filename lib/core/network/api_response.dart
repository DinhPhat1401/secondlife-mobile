class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: rawData != null && fromJsonT != null ? fromJsonT(rawData) : rawData as T?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

class PageResponse<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  PageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) fromJsonItem,
  ) {
    // Handle both Spring Data Page ('content') and custom Page ('items')
    final rawList = json['items'] ?? json['content'] ?? [];
    final List<T> items = (rawList as List).map((i) => fromJsonItem(i)).toList();

    final page = json['page'] ?? json['number'] ?? 0;
    final size = json['size'] ?? 10;
    final totalElements = json['totalElements'] ?? items.length;
    final totalPages = json['totalPages'] ?? 1;
    final isLast = json['isLast'] ?? json['last'] ?? (page >= totalPages - 1);

    return PageResponse<T>(
      items: items,
      page: (page as num).toInt(),
      size: (size as num).toInt(),
      totalElements: (totalElements as num).toInt(),
      totalPages: (totalPages as num).toInt(),
      isLast: isLast as bool,
    );
  }
}
