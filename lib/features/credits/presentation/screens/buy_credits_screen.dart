import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/credits/domain/credit_models.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/features/wallet/presentation/wallet_providers.dart';

class BuyCreditsScreen extends ConsumerStatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  ConsumerState<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends ConsumerState<BuyCreditsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String? _purchasingPackageId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchasePackage(TopupPackageModel pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận mua gói ${pkg.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giá gói: ${_currencyFormat.format(pkg.price)}'),
            const SizedBox(height: 8),
            const Text(
              'Số tiền sẽ được trừ trực tiếp từ số dư ví SecondLife của bạn và điểm tín dụng sẽ được cộng ngay lập tức.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thanh Toán Trừ Ví', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _purchasingPackageId = pkg.id);
    final ok = await ref.read(creditNotifierProvider.notifier).purchaseTopupPackage(pkg.id);
    if (!mounted) return;
    setState(() => _purchasingPackageId = null);

    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Mua gói thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn đã kích hoạt thành công gói ${pkg.name}:'),
              const SizedBox(height: 8),
              if (pkg.postCredits > 0)
                Text('• +${pkg.postCredits} lượt đăng bài gia dụng', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (pkg.chatCredits > 0)
                Text('• +${pkg.chatCredits} lượt chat trợ lý AI', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (pkg.valuationCredits > 0)
                Text('• +${pkg.valuationCredits} lượt định giá AI thông minh', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Xong', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      final err = ref.read(creditNotifierProvider).errorMessage ?? 'Không thể thanh toán gói';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showQrDepositSheet(double shortageAmount) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrDepositModal(
        shortageAmount: shortageAmount,
        currencyFormat: _currencyFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditNotifierProvider);
    final walletState = ref.watch(sellerWalletNotifierProvider);
    final walletBalance = walletState.wallet?.balance ?? 0.0;
    final allPackages = creditState.topupPackages;

    final comboPackages = allPackages.where((p) => p.isCombo).toList();
    final singlePackages = allPackages.where((p) => !p.isCombo).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mua Gói Tín Dụng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử biến động tín dụng',
            onPressed: () => context.push('/credits/ledger'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () async {
              await Future.wait([
                ref.read(creditNotifierProvider.notifier).loadInitialData(),
                ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
              ]);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(creditNotifierProvider.notifier).loadInitialData(),
            ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance & Wallet overview card
              _buildBalanceSummaryCard(creditState.balance, walletBalance),
              const SizedBox(height: 16),

              // Tab selection: Combos vs Single packages
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'Gói Combo Ưu Đãi (${comboPackages.length})'),
                    Tab(text: 'Gói Lẻ Từng Phần (${singlePackages.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Packages Content
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Combos
                    comboPackages.isEmpty
                        ? _buildEmptyState('Đang tải danh sách combo...')
                        : ListView.separated(
                            itemCount: comboPackages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final pkg = comboPackages[idx];
                              return _buildPackageCard(pkg, walletBalance);
                            },
                          ),

                    // Tab 2: Single packages
                    singlePackages.isEmpty
                        ? _buildEmptyState('Đang tải danh sách gói...')
                        : ListView.separated(
                            itemCount: singlePackages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final pkg = singlePackages[idx];
                              return _buildPackageCard(pkg, walletBalance);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard(CreditBalanceModel balance, double walletBalance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Số Dư Tín Dụng Hiện Có',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Ví: ${_currencyFormat.format(walletBalance)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCreditStatItem(Icons.post_add, '${balance.postCredits}', 'Lượt Đăng Bài', AppColors.primary),
              Container(width: 1, height: 28, color: AppColors.border),
              _buildCreditStatItem(Icons.auto_awesome, '${balance.chatCredits}', 'Lượt Chat AI', AppColors.info),
              Container(width: 1, height: 28, color: AppColors.border),
              _buildCreditStatItem(Icons.psychology_outlined, '${balance.valuationCredits}', 'Lượt Định Giá', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(TopupPackageModel pkg, double walletBalance) {
    final hasDiscount = pkg.discountPercentage > 0;
    final isAffordable = walletBalance >= pkg.price;
    final shortage = pkg.price - walletBalance;
    final isPurchasing = _purchasingPackageId == pkg.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pkg.isCombo ? const Color(0xFFC34C36).withValues(alpha: 0.3) : AppColors.border,
          width: pkg.isCombo ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row Header: Name & Discount Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pkg.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'GIẢM ${pkg.discountPercentage.toStringAsFixed(1).replaceAll('.0', '')}%',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Price Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currencyFormat.format(pkg.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text(
                    _currencyFormat.format(pkg.originalPrice),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Benefits List
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (pkg.postCredits > 0)
                    _buildBenefitRow(Icons.local_offer_outlined, '+${pkg.postCredits} Lượt đăng tin bài'),
                  if (pkg.chatCredits > 0)
                    _buildBenefitRow(Icons.auto_awesome, '+${pkg.chatCredits} Lượt Chat AI'),
                  if (pkg.valuationCredits > 0)
                    _buildBenefitRow(Icons.search, '+${pkg.valuationCredits} Lượt định giá AI'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // English / Technical description
            Text(
              pkg.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Action Row
            Row(
              children: [
                if (!isAffordable) ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => _showQrDepositSheet(shortage),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2, size: 18, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Thiếu ${_currencyFormat.format(shortage)} (Quét QR nạp thêm)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAffordable ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    foregroundColor: isAffordable ? Colors.white : const Color(0xFF94A3B8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isAffordable && !isPurchasing
                      ? () => _handlePurchasePackage(pkg)
                      : null,
                  child: isPurchasing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          pkg.isCombo ? 'Combo Trừ Ví' : 'Mua Trừ Ví',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isAffordable ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QrDepositModal extends ConsumerStatefulWidget {
  final double shortageAmount;
  final NumberFormat currencyFormat;

  const _QrDepositModal({
    required this.shortageAmount,
    required this.currencyFormat,
  });

  @override
  ConsumerState<_QrDepositModal> createState() => _QrDepositModalState();
}

class _QrDepositModalState extends ConsumerState<_QrDepositModal> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _depositData;

  @override
  void initState() {
    super.initState();
    _requestDeposit();
  }

  Future<void> _requestDeposit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(walletRepositoryProvider);
      final res = await repo.createDepositRequest(widget.shortageAmount);
      if (mounted) {
        setState(() {
          _depositData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nạp Tiền Nhanh Qua VietQR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestDeposit,
                    child: const Text('Thử Lại'),
                  ),
                ],
              ),
            )
          else if (_depositData != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://img.vietqr.io/image/${_depositData!['bankName']}-${_depositData!['bankAccountNumber']}-compact2.png?amount=${_depositData!['amount']}&addInfo=${_depositData!['code']}&accountName=${Uri.encodeComponent(_depositData!['bankAccountName'] ?? '')}',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.qr_code, size: 64, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildTransferInfoRow('Ngân hàng:', '${_depositData!['bankName']}'),
                  _buildTransferInfoRow('Số tài khoản:', '${_depositData!['bankAccountNumber']}'),
                  _buildTransferInfoRow('Chủ tài khoản:', '${_depositData!['bankAccountName']}'),
                  _buildTransferInfoRow('Số tiền:', widget.currencyFormat.format(_depositData!['amount'])),
                  _buildTransferInfoRow('Nội dung chuyển:', '${_depositData!['code']}', isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await Future.wait([
                  ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
                  ref.read(creditNotifierProvider.notifier).loadInitialData(),
                ]);
              },
              child: const Text(
                'Tôi Đã Chuyển Khoản Xong',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
