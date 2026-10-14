import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../data/credit_repository.dart';
import '../domain/credit_models.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CreditRepository(client: client);
});

class CreditState {
  final bool isLoading;
  final String? errorMessage;
  final CreditBalanceModel balance;
  final List<CreditPricingRuleModel> prices;
  final List<CreditDiscountTierModel> discountTiers;
  final CreditQuoteModel quote;
  final List<CreditLedgerItemModel> ledger;

  const CreditState({
    this.isLoading = false,
    this.errorMessage,
    this.balance = const CreditBalanceModel(),
    this.prices = const [],
    this.discountTiers = const [],
    this.quote = const CreditQuoteModel(),
    this.ledger = const [],
  });

  CreditState copyWith({
    bool? isLoading,
    String? errorMessage,
    CreditBalanceModel? balance,
    List<CreditPricingRuleModel>? prices,
    List<CreditDiscountTierModel>? discountTiers,
    CreditQuoteModel? quote,
    List<CreditLedgerItemModel>? ledger,
  }) {
    return CreditState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      balance: balance ?? this.balance,
      prices: prices ?? this.prices,
      discountTiers: discountTiers ?? this.discountTiers,
      quote: quote ?? this.quote,
      ledger: ledger ?? this.ledger,
    );
  }
}

class CreditNotifier extends Notifier<CreditState> {
  @override
  CreditState build() {
    Future.microtask(() => loadInitialData());
    return const CreditState(isLoading: true);
  }

  CreditRepository get _repo => ref.read(creditRepositoryProvider);

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final balance = await _repo.getCredits();
      final pricingData = await _repo.getPricing(listingQuantity: 5, valuationQuantity: 5);

      final prices = pricingData['prices'] as List<CreditPricingRuleModel>? ?? [];
      final discountTiers = pricingData['discountTiers'] as List<CreditDiscountTierModel>? ?? [];
      final quote = pricingData['quote'] as CreditQuoteModel? ??
          _calculateLocalQuote(
            listingQty: 5,
            valuationQty: 5,
            prices: prices,
            tiers: discountTiers,
          );

      state = state.copyWith(
        isLoading: false,
        balance: balance,
        prices: prices,
        discountTiers: discountTiers,
        quote: quote,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateQuote({
    required int listingQty,
    required int valuationQty,
  }) async {
    try {
      final pricingData = await _repo.getPricing(
        listingQuantity: listingQty,
        valuationQuantity: valuationQty,
      );

      final serverQuote = pricingData['quote'] as CreditQuoteModel?;
      final quote = serverQuote ??
          _calculateLocalQuote(
            listingQty: listingQty,
            valuationQty: valuationQty,
            prices: state.prices,
            tiers: state.discountTiers,
          );

      state = state.copyWith(quote: quote);
    } catch (_) {
      // Fallback local calculation
      final localQuote = _calculateLocalQuote(
        listingQty: listingQty,
        valuationQty: valuationQty,
        prices: state.prices,
        tiers: state.discountTiers,
      );
      state = state.copyWith(quote: localQuote);
    }
  }

  CreditQuoteModel _calculateLocalQuote({
    required int listingQty,
    required int valuationQty,
    required List<CreditPricingRuleModel> prices,
    required List<CreditDiscountTierModel> tiers,
  }) {
    double listingUnitPrice = 10000;
    double valuationUnitPrice = 5000;

    for (final p in prices) {
      if (p.creditType == 'LISTING') listingUnitPrice = p.unitPrice;
      if (p.creditType == 'VALUATION') valuationUnitPrice = p.unitPrice;
    }

    final subtotal = (listingQty * listingUnitPrice) + (valuationQty * valuationUnitPrice);
    final totalQty = listingQty + valuationQty;

    double discountRate = 0.0;
    for (final tier in tiers) {
      if (tier.active && totalQty >= tier.minQuantity) {
        if (tier.maxQuantity == null || totalQty <= tier.maxQuantity!) {
          if (tier.discountRate > discountRate) {
            discountRate = tier.discountRate;
          }
        }
      }
    }

    final discountAmount = subtotal * discountRate;
    final finalFee = subtotal - discountAmount;

    return CreditQuoteModel(
      listingQuantity: listingQty,
      valuationQuantity: valuationQty,
      listingUnitPrice: listingUnitPrice,
      valuationUnitPrice: valuationUnitPrice,
      discountRate: discountRate,
      subtotal: subtotal,
      discountAmount: discountAmount,
      finalFee: finalFee,
    );
  }

  Future<CreditPurchaseModel?> purchaseCredits({
    required int listingQty,
    required int valuationQty,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final purchase = await _repo.createPurchase(
        listingQuantity: listingQty,
        valuationQuantity: valuationQty,
      );

      // Refresh balance after purchase
      final newBalance = await _repo.getCredits();
      state = state.copyWith(isLoading: false, balance: newBalance);
      return purchase;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> loadLedger() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repo.getLedger(page: 0, size: 50);
      state = state.copyWith(isLoading: false, ledger: page.items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final creditNotifierProvider =
    NotifierProvider<CreditNotifier, CreditState>(CreditNotifier.new);
