import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';
import 'package:secondlife_app_seller/features/catalog/presentation/catalog_providers.dart';

class Step1PhotosInit extends ConsumerStatefulWidget {
  const Step1PhotosInit({super.key});

  @override
  ConsumerState<Step1PhotosInit> createState() => _Step1PhotosInitState();
}

class _Step1PhotosInitState extends ConsumerState<Step1PhotosInit> {
  final ImagePicker _picker = ImagePicker();

  final List<String> _photoSlotLabels = [
    'Mặt trước tổng quan *',
    'Mặt sau / Dây nguồn *',
    'Tem thông số kỹ thuật *',
    'Khoang bên trong',
    'Góc cạnh / Trầy xước',
    'Phụ kiện & Dụng cụ',
  ];

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final currentPhotos = List<File>.from(ref.read(createListingNotifierProvider).photos);
        if (index < currentPhotos.length) {
          currentPhotos[index] = File(picked.path);
        } else {
          currentPhotos.add(File(picked.path));
        }
        ref.read(createListingNotifierProvider.notifier).setPhotos(currentPhotos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImageSourceDialog(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Chụp ảnh thực tế bằng Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Chọn ảnh từ Thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    final currentPhotos = List<File>.from(ref.read(createListingNotifierProvider).photos);
    if (index < currentPhotos.length) {
      currentPhotos.removeAt(index);
      ref.read(createListingNotifierProvider.notifier).setPhotos(currentPhotos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final photos = state.photos;
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = state.categoryId ?? '';
    final itemsAsync = ref.watch(itemsByCategoryProvider(selectedCategoryId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI Vision Nhận Diện Thiết Bị',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chọn danh mục và chụp đủ tối thiểu 3 ảnh rõ nét (đặc biệt là tem thông số) để trợ lý AI tự động nhận diện model, năm sản xuất và gợi ý mô tả chi tiết.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category & Item Selector Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (state.errorMessage != null && (state.categoryId == null || state.categoryId!.isEmpty))
                    ? AppColors.error
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Danh Mục Thiết Bị Gia Dụng *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'Chọn danh mục thiết bị',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    initialValue: categories.any((c) => c.id == state.categoryId) ? state.categoryId : null,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(
                              categoryId: val,
                              itemId: '',
                            );
                      }
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
                  error: (err, stack) => const Text(
                    'Không thể tải danh mục. Vui lòng kiểm tra kết nối.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),

                if (selectedCategoryId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Loại Thiết Bị Cụ Thể (Tùy chọn)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  itemsAsync.when(
                    data: (items) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Chọn loại thiết bị (Nồi cơm, Lò vi sóng...)',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      initialValue: items.any((i) => i.id == state.itemId) ? state.itemId : null,
                      items: items.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(itemId: val);
                        }
                      },
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Photos Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hình Ảnh Thiết Bị Thực Tế *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              Text(
                '${photos.length}/6 ảnh (Tối thiểu 3)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: photos.length >= 3 ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Photo Grid (6 slots)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final hasImage = index < photos.length;
              final label = _photoSlotLabels[index];

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showImageSourceDialog(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasImage ? AppColors.primary : AppColors.border,
                      width: hasImage ? 1.5 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.file(photos[index], fit: BoxFit.cover)
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 22),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: label.contains('*') ? FontWeight.bold : FontWeight.w500,
                                    color: label.contains('*') ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),

                        // Delete button overlay
                        if (hasImage)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),

                        // Label footer
                        if (hasImage)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              color: Colors.black.withValues(alpha: 0.6),
                              child: Text(
                                label,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Error message
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Step 1 Button
          SlButton(
            text: 'Tiếp Tục: Phân Tích Với AI (${photos.length}/6 ảnh)',
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: photos.length >= 3
                ? () async {
                    if (state.categoryId == null || state.categoryId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn Danh Mục Thiết Bị trước khi phân tích AI'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    await ref.read(createListingNotifierProvider.notifier).initPost();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
