import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../credits/presentation/credit_providers.dart';
import '../../listings/domain/post_models.dart';
import '../../listings/presentation/seller_listings_providers.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/presentation/order_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final creditState = ref.watch(creditNotifierProvider);
    final walletState = ref.watch(sellerWalletNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final listingsState = ref.watch(sellerListingsNotifierProvider);
    final orderState = ref.watch(orderListNotifierProvider);
    final user = authState.user;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final hideBalance = ref.watch(hideWalletBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Người bán SecondLife',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.isSeller == true ? 'Shop Đã Xác Thực' : 'Chưa Định Danh Người Bán',
                        style: TextStyle(
                          fontSize: 11,
                          color: user?.isSeller == true ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: unreadCount > 0
                ? Badge(
                    label: Text('$unreadCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(creditNotifierProvider.notifier).loadInitialData(),
            ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
            ref.read(sellerListingsNotifierProvider.notifier).loadListings(),
            ref.read(orderListNotifierProvider.notifier).loadOrders(),
            ref.read(notificationNotifierProvider.notifier).loadData(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner: Needs eKYC Verification
            if (user?.isSeller != true)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kích hoạt Quyền Bán Hàng',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Hoàn tất định danh eKYC để đăng bán thiết bị gia dụng',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push('/seller-onboarding'),
                      child: const Text('Xác thực', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

            // Unified Wallet & Credit Hub Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- TOP: SỐ DƯ VÍ NỘI BỘ ---
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Số Dư Ví Nội Bộ',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/wallet'),
                              child: const Text(
                                'Chi tiết >',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              hideBalance
                                  ? '•••••••• đ'
                                  : currencyFormatter.format(walletState.wallet?.balance ?? 0.0),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: hideBalance ? 'Hiện số dư' : 'Ẩn số dư',
                              onPressed: () {
                                ref.read(hideWalletBalanceProvider.notifier).toggle();
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                label: const Text('Rút tiền về ngân hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: () => context.push('/wallet'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- SUBTLE DIVIDER ---
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // --- BOTTOM: TÍN DỤNG SECONDLIFE ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFD),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Tín Dụng SecondLife',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/credits/buy'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, color: AppColors.primary, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Mua thêm',
                                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lượt Đăng Tin',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${creditState.balance.postCredits} lượt',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lượt Chat AI',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${creditState.balance.chatCredits} lượt',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lượt AI Định Giá',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${creditState.balance.valuationCredits} lượt',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Quick Stats
            const Text(
              'Tình Hình Kinh Doanh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatBox(
                  context,
                  listingsState.listings.where((p) => p.status == ListingStatus.active).length.toString(),
                  'Đang bán',
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatBox(
                  context,
                  orderState.orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.pending || o.status == OrderStatus.shipping).length.toString(),
                  'Đơn hàng',
                  Icons.local_shipping_outlined,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatBox(
                  context,
                  listingsState.listings.where((p) => p.status == ListingStatus.pending || p.status == ListingStatus.draft).length.toString(),
                  'Nháp / Duyệt',
                  Icons.hourglass_top_rounded,
                  AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Shortcut Actions
            const Text(
              'Thao Tác Nhanh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
              ),
              title: const Text('Đăng Tin Đồ Gia Dụng Mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Hỗ trợ trợ lý AI viết mô tả và định giá', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => context.push('/create-listing'),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFF4F46E5)),
              ),
              title: const Text('Cài Đặt Kho Lấy Hàng (GPS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Chọn địa chỉ trên bản đồ để tài xế Lalamove tới lấy', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => context.push('/seller-address'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
