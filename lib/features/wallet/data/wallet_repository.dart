import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/wallet_models.dart';

class WalletRepository {
  final ApiClient client;

  WalletRepository({required this.client});

  Future<SellerWalletModel> getMyWallet() async {
    try {
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.walletMe);
      final data = response.data;
      if (data != null) {
        return SellerWalletModel.fromJson(data);
      }
      return _getMockWallet();
    } catch (_) {
      return _getMockWallet();
    }
  }

  Future<List<WalletTransactionModel>> getTransactions({int page = 0, int size = 20}) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data != null && data['content'] is List) {
        return (data['content'] as List)
            .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _getMockTransactions();
    } catch (_) {
      return _getMockTransactions();
    }
  }

  Future<List<WalletWithdrawalModel>> getWithdrawals({int page = 0, int size = 20}) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.walletWithdrawals,
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data != null && data['content'] is List) {
        return (data['content'] as List)
            .map((item) => WalletWithdrawalModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _getMockWithdrawals();
    } catch (_) {
      return _getMockWithdrawals();
    }
  }

  Future<WalletWithdrawalModel> requestWithdrawal({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final response = await client.post<Map<String, dynamic>>(
        ApiEndpoints.walletWithdrawals,
        data: {
          'amount': amount,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName.toUpperCase().trim(),
        },
      );
      if (response.data != null) {
        return WalletWithdrawalModel.fromJson(response.data!);
      }
      return WalletWithdrawalModel(
        id: 'wd-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName.toUpperCase().trim(),
        status: WithdrawalStatus.pendingReview,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return WalletWithdrawalModel(
        id: 'wd-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName.toUpperCase().trim(),
        status: WithdrawalStatus.pendingReview,
        createdAt: DateTime.now(),
      );
    }
  }

  SellerWalletModel _getMockWallet() {
    return SellerWalletModel(
      id: 'wallet-001',
      userId: 'usr-seller-01',
      balance: 4850000.0,
      pendingBalance: 1250000.0, // Đang giao qua Lalamove chưa hoàn tất
      totalWithdrawn: 12000000.0,
      updatedAt: DateTime.now(),
    );
  }

  List<WalletTransactionModel> _getMockTransactions() {
    final now = DateTime.now();
    return [
      WalletTransactionModel(
        id: 'tx-001',
        amount: 3800000.0,
        type: WalletTransactionType.orderPayout,
        description: 'Thanh toán hoàn tất đơn hàng #ORD-8821 (Tủ lạnh Panasonic)',
        referenceId: 'ORD-8821',
        balanceAfter: 4850000.0,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      WalletTransactionModel(
        id: 'tx-002',
        amount: 190000.0,
        type: WalletTransactionType.commissionFee,
        description: 'Phí hoa hồng sàn 5% đơn hàng #ORD-8821',
        referenceId: 'ORD-8821',
        balanceAfter: 1050000.0,
        createdAt: now.subtract(const Duration(hours: 4, minutes: 1)),
      ),
      WalletTransactionModel(
        id: 'tx-003',
        amount: 2000000.0,
        type: WalletTransactionType.withdrawal,
        description: 'Rút tiền về Vietcombank ****5678',
        referenceId: 'WD-2910',
        balanceAfter: 1240000.0,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      WalletTransactionModel(
        id: 'tx-004',
        amount: 850000.0,
        type: WalletTransactionType.orderPayout,
        description: 'Thanh toán hoàn tất đơn hàng #ORD-7740 (Quạt Mitsubishi)',
        referenceId: 'ORD-7740',
        balanceAfter: 3240000.0,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<WalletWithdrawalModel> _getMockWithdrawals() {
    final now = DateTime.now();
    return [
      WalletWithdrawalModel(
        id: 'wd-001',
        amount: 2000000.0,
        bankCode: 'VCB',
        bankName: 'Vietcombank',
        accountNumber: '1019283746',
        accountHolderName: 'NGUYEN VAN BAN',
        status: WithdrawalStatus.approved,
        createdAt: now.subtract(const Duration(days: 3)),
        processedAt: now.subtract(const Duration(days: 3, hours: -1)),
      ),
      WalletWithdrawalModel(
        id: 'wd-002',
        amount: 5000000.0,
        bankCode: 'MB',
        bankName: 'MB Bank',
        accountNumber: '098877665544',
        accountHolderName: 'NGUYEN VAN BAN',
        status: WithdrawalStatus.approved,
        createdAt: now.subtract(const Duration(days: 15)),
        processedAt: now.subtract(const Duration(days: 14)),
      ),
      WalletWithdrawalModel(
        id: 'wd-003',
        amount: 500000.0,
        bankCode: 'TCB',
        bankName: 'Techcombank',
        accountNumber: '19033445566',
        accountHolderName: 'NGUYEN VAN BAN',
        status: WithdrawalStatus.rejected,
        adminNote: 'Tên chủ tài khoản không khớp với thông tin định danh eKYC.',
        createdAt: now.subtract(const Duration(days: 20)),
        processedAt: now.subtract(const Duration(days: 20, hours: -2)),
      ),
    ];
  }
}
