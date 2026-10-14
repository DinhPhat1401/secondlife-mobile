import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';
import 'package:secondlife_app_seller/features/listings/domain/post_models.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step5ShippingPackage extends ConsumerStatefulWidget {
  const Step5ShippingPackage({super.key});

  @override
  ConsumerState<Step5ShippingPackage> createState() => _Step5ShippingPackageState();
}

class _Step5ShippingPackageState extends ConsumerState<Step5ShippingPackage> {
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Nồi chiên / Nồi cơm', 'w': 3000, 'l': 30, 'wid': 30, 'h': 35},
    {'name': 'Lò vi sóng', 'w': 12000, 'l': 50, 'wid': 40, 'h': 35},
    {'name': 'Quạt cây đứng', 'w': 5000, 'l': 45, 'wid': 45, 'h': 85},
    {'name': 'Máy hút bụi', 'w': 4000, 'l': 40, 'wid': 30, 'h': 30},
    {'name': 'Máy giặt / Tủ lạnh mini', 'w': 28000, 'l': 60, 'wid': 60, 'h': 85},
  ];

  @override
  void initState() {
    super.initState();
    final pkg = ref.read(createListingNotifierProvider).shippingPackage;
    _weightController.text = pkg.weightGrams.toString();
    _lengthController.text = pkg.lengthCm.toString();
    _widthController.text = pkg.widthCm.toString();
    _heightController.text = pkg.heightCm.toString();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> p) {
    setState(() {
      _weightController.text = p['w'].toString();
      _lengthController.text = p['l'].toString();
      _widthController.text = p['wid'].toString();
      _heightController.text = p['h'].toString();
    });
    _savePackage();
  }

  void _savePackage() {
    final w = int.tryParse(_weightController.text) ?? 1000;
    final l = int.tryParse(_lengthController.text) ?? 20;
    final wid = int.tryParse(_widthController.text) ?? 20;
    final h = int.tryParse(_heightController.text) ?? 20;

    ref.read(createListingNotifierProvider.notifier).setShippingPackage(
          ShippingPackageModel(
            weightGrams: w,
            lengthCm: l,
            widthCm: wid,
            heightCm: h,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final w = int.tryParse(_weightController.text) ?? 0;
    final l = int.tryParse(_lengthController.text) ?? 0;
    final wid = int.tryParse(_widthController.text) ?? 0;
    final h = int.tryParse(_heightController.text) ?? 0;
    final volumetricWeightKg = (l * wid * h) / 5000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Guide
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông Số Đóng Gói Vận Chuyển',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dùng để tính phí giao hàng Lalamove / GHN tự động khi người mua đặt đơn.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preset Chips
          const Text('Chọn mẫu thiết bị tương đương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              return ActionChip(
                label: Text(p['name'] as String, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                onPressed: () => _applyPreset(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Weight Input
          SlTextField(
            label: 'Trọng lượng sau đóng gói (gram) *',
            hint: 'VD: 3000 (tương đương 3 kg)',
            controller: _weightController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _savePackage(),
          ),
          const SizedBox(height: 16),

          // Dimensions Inputs
          const Text('Kích thước 3 chiều đóng hộp (cm) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SlTextField(
                  label: 'Dài (cm)',
                  hint: '30',
                  controller: _lengthController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _savePackage(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SlTextField(
                  label: 'Rộng (cm)',
                  hint: '30',
                  controller: _widthController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _savePackage(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SlTextField(
                  label: 'Cao (cm)',
                  hint: '35',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _savePackage(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Volumetric Calculation Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khối lượng thực tế', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('${(w / 1000).toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Icon(Icons.compare_arrows_rounded, color: AppColors.textMuted),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Khối lượng quy đổi (Lalamove)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('${volumetricWeightKg.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Step 5
          SlButton(
            text: 'Tiếp Tục: Xem Trước & Đăng Bán',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            onPressed: () {
              _savePackage();
              ref.read(createListingNotifierProvider.notifier).goToStep(5);
            },
          ),
        ],
      ),
    );
  }
}
