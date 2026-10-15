import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../profile_providers.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/edit_profile_sheet.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ & Cài Đặt Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(profileNotifierProvider.notifier).loadProfile(),
          ),
        ],
      ),
      body: state.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Không tìm thấy thông tin hồ sơ'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(profileNotifierProvider.notifier).loadProfile(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card: Avatar & Name
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(44),
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    color: AppColors.primaryLight,
                                    child: profile.avatarUrl.isNotEmpty
                                        ? Image.network(
                                            profile.avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'S',
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'S',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.fullName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => EditProfileSheet.show(context, profile),
                                ),
                              ],
                            ),
                            Text(
                              profile.email,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            if (profile.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                profile.phone,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // eKYC Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: profile.isSeller ? AppColors.successLight : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    profile.isSeller ? Icons.verified : Icons.error_outline,
                                    color: profile.isSeller ? AppColors.success : AppColors.warning,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    profile.isSeller ? 'Shop Đã Xác Thực eKYC' : 'Chưa Định Danh Người Bán',
                                    style: TextStyle(
                                      color: profile.isSeller ? AppColors.success : AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (profile.createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Thành viên từ: ${dateFormatter.format(profile.createdAt!)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: Warehouse / Pickup Address (Lalamove)
                      _buildSectionTitle('Kho Hàng & Giao Vận Lalamove'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on_outlined, color: AppColors.info, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Địa chỉ lấy hàng mặc định',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              profile.fullAddress,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                            ),
                            if (profile.latitude != null && profile.longitude != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.gps_fixed, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GPS: ${profile.latitude!.toStringAsFixed(4)}, ${profile.longitude!.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text('Thay Đổi Tọa Độ Trên Bản Đồ'),
                                onPressed: () async {
                                  final result = await context.push<Map<String, dynamic>?>(
                                    '/seller-address',
                                    extra: {
                                      'initialLat': profile.latitude,
                                      'initialLng': profile.longitude,
                                      'initialAddress': profile.streetAddress,
                                    },
                                  );
                                  if (result != null && result['address'] != null) {
                                    final addr = result['address'] as String;
                                    final lat = (result['lat'] as num?)?.toDouble() ?? 21.0285;
                                    final lng = (result['lng'] as num?)?.toDouble() ?? 105.8542;
                                    await ref
                                        .read(profileNotifierProvider.notifier)
                                        .updatePickupAddress(address: addr, lat: lat, lng: lng);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã cập nhật kho lấy hàng Lalamove thành công!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: Settings & Shortcuts
                      _buildSectionTitle('Tài Khoản & Tiện Ích'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Đổi Mật Khẩu',
                              subtitle: 'Cập nhật mật khẩu bảo mật định kỳ',
                              onTap: () async {
                                final success = await ChangePasswordSheet.show(context);
                                if (success == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đổi mật khẩu thành công!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSettingsTile(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Ví Doanh Thu & Rút Tiền',
                              subtitle: 'Quản lý tài khoản ngân hàng thụ hưởng',
                              onTap: () => context.push('/wallet'),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSettingsTile(
                              icon: Icons.stars_outlined,
                              title: 'Gói Tín Dụng SecondLife',
                              subtitle: 'Xem bảng chiết khấu & lịch sử nạp credit',
                              onTap: () => context.push('/credits/ledger'),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSettingsTile(
                              icon: Icons.notifications_none_outlined,
                              title: 'Trung Tâm Thông Báo',
                              subtitle: 'Cài đặt cảnh báo đơn hàng và tin nhắn',
                              onTap: () => context.push('/notifications'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Đăng Xuất Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận đăng xuất'),
                              content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng người bán không?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await ref.read(authNotifierProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // App Version Footer
                      const Center(
                        child: Text(
                          'SecondLife Seller App • Phiên bản 1.2.0 (Build 20261014)\nNền tảng thanh lý đồ gia dụng cũ thông minh',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}
