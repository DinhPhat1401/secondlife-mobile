import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/catalog/presentation/catalog_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step3ProductSpecs extends ConsumerStatefulWidget {
  const Step3ProductSpecs({super.key});

  @override
  ConsumerState<Step3ProductSpecs> createState() => _Step3ProductSpecsState();
}

class _Step3ProductSpecsState extends ConsumerState<Step3ProductSpecs> {
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> _popularBrands = [
    'Panasonic',
    'Electrolux',
    'Sunhouse',
    'Philips',
    'BlueStone',
    'Sharp',
    'Kangaroo',
    'Cuckoo',
    'Lock&Lock',
    'Tefal',
    'Toshiba',
    'Samsung',
    'LG',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createListingNotifierProvider);
    _titleController.text = state.title;
    _brandController.text = state.brand;
    _modelController.text = state.model;
    _descController.text = state.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveCurrentFields() {
    final notifier = ref.read(createListingNotifierProvider.notifier);
    notifier.setTitle(_titleController.text.trim());
    notifier.setDescription(_descController.text.trim());
    notifier.updateBasicSpecs(
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = state.categoryId ?? '';
    final itemsAsync = ref.watch(itemsByCategoryProvider(selectedCategoryId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selector
          const Text('Danh Mục Gia Dụng *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Chọn Danh Mục', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  value: categories.any((c) => c.id == state.categoryId) ? state.categoryId : null,
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(categoryId: val, itemId: '');
                    }
                  },
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => const Text('Không tải được danh mục'),
          ),
          const SizedBox(height: 16),

          // Item Selector
          if (selectedCategoryId.isNotEmpty) ...[
            const Text('Loại Thiết Bị *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            itemsAsync.when(
              data: (items) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Chọn Loại Thiết Bị', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    value: items.any((i) => i.id == state.itemId) ? state.itemId : null,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(itemId: val);
                      }
                    },
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],

          // Brand & Model Row
          Row(
            children: [
              Expanded(
                child: SlTextField(
                  label: 'Thương hiệu *',
                  hint: 'VD: Panasonic, Sunhouse',
                  controller: _brandController,
                  onChanged: (v) => ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(brand: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlTextField(
                  label: 'Mã Model',
                  hint: 'VD: SHD7723',
                  controller: _modelController,
                  onChanged: (v) => ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(model: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Brand Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _popularBrands.take(6).map((b) {
              return ActionChip(
                label: Text(b, style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                onPressed: () {
                  _brandController.text = b;
                  ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(brand: b);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Condition Grade
          const Text('Tình Trạng Thiết Bị *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Column(
            children: ApplianceCondition.values.map((cond) {
              final isSelected = state.condition == cond;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(createListingNotifierProvider.notifier).updateBasicSpecs(condition: cond);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cond.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(cond.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Title with AI Suggestion Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiêu Đề Bài Viết *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                label: const Text('Gợi Ý AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  _saveCurrentFields();
                  await ref.read(createListingNotifierProvider.notifier).suggestTitle();
                  _titleController.text = ref.read(createListingNotifierProvider).title;
                },
              ),
            ],
          ),
          SlTextField(
            label: 'Tiêu Đề Bài Viết *',
            hint: 'VD: Nồi chiên không dầu Panasonic 6L mới 98% còn bảo hành',
            controller: _titleController,
            maxLines: 2,
            onChanged: (v) => ref.read(createListingNotifierProvider.notifier).setTitle(v),
          ),
          const SizedBox(height: 16),

          SlTextField(
            label: 'Nội Dung Mô Tả Chi Tiết (Sinh bởi AI)',
            hint: 'Mô tả chi tiết tính năng, nguồn gốc, phụ kiện và tình trạng máy...',
            controller: _descController,
            maxLines: 6,
            onChanged: (v) => ref.read(createListingNotifierProvider.notifier).setDescription(v),
          ),
          const SizedBox(height: 24),

          // Submit Step 3
          SlButton(
            text: 'Tiếp Tục: Định Giá Thị Trường AI',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            onPressed: () {
              _saveCurrentFields();
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tiêu đề bài viết'), backgroundColor: AppColors.error),
                );
                return;
              }
              ref.read(createListingNotifierProvider.notifier).goToStep(3);
            },
          ),
        ],
      ),
    );
  }
}
