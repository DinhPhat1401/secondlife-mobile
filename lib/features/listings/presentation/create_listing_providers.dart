import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import '../data/post_repository.dart';
import '../domain/post_models.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PostRepository(client: client);
});

class CreateListingState {
  final int step; // 0 to 5
  final bool isLoading;
  final String? errorMessage;
  final String? postId;
  final String? aiSessionId;
  final List<File> photos;
  final List<String> suggestedQuestions;
  final List<AiChatMessageModel> chatMessages;
  final String description;
  final String? categoryId;
  final String? itemId;
  final String brand;
  final String model;
  final int purchaseYear;
  final ApplianceCondition condition;
  final String title;
  final AiPriceEstimationModel? priceEstimation;
  final double userPriceVnd;
  final ShippingPackageModel shippingPackage;
  final bool isSubmitted;

  const CreateListingState({
    this.step = 0,
    this.isLoading = false,
    this.errorMessage,
    this.postId,
    this.aiSessionId,
    this.photos = const [],
    this.suggestedQuestions = const [],
    this.chatMessages = const [],
    this.description = '',
    this.categoryId,
    this.itemId,
    this.brand = '',
    this.model = '',
    this.purchaseYear = 2024,
    this.condition = ApplianceCondition.usedGood,
    this.title = '',
    this.priceEstimation,
    this.userPriceVnd = 0.0,
    this.shippingPackage = const ShippingPackageModel(),
    this.isSubmitted = false,
  });

  CreateListingState copyWith({
    int? step,
    bool? isLoading,
    String? errorMessage,
    String? postId,
    String? aiSessionId,
    List<File>? photos,
    List<String>? suggestedQuestions,
    List<AiChatMessageModel>? chatMessages,
    String? description,
    String? categoryId,
    String? itemId,
    String? brand,
    String? model,
    int? purchaseYear,
    ApplianceCondition? condition,
    String? title,
    AiPriceEstimationModel? priceEstimation,
    double? userPriceVnd,
    ShippingPackageModel? shippingPackage,
    bool? isSubmitted,
  }) {
    return CreateListingState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      postId: postId ?? this.postId,
      aiSessionId: aiSessionId ?? this.aiSessionId,
      photos: photos ?? this.photos,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      chatMessages: chatMessages ?? this.chatMessages,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      purchaseYear: purchaseYear ?? this.purchaseYear,
      condition: condition ?? this.condition,
      title: title ?? this.title,
      priceEstimation: priceEstimation ?? this.priceEstimation,
      userPriceVnd: userPriceVnd ?? this.userPriceVnd,
      shippingPackage: shippingPackage ?? this.shippingPackage,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

class CreateListingNotifier extends Notifier<CreateListingState> {
  @override
  CreateListingState build() {
    return CreateListingState(purchaseYear: DateTime.now().year);
  }

  PostRepository get _repo => ref.read(postRepositoryProvider);

  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(step: step);
    }
  }

  void setPhotos(List<File> photos) {
    state = state.copyWith(photos: photos);
  }

  void updateBasicSpecs({
    String? categoryId,
    String? itemId,
    String? brand,
    String? model,
    int? purchaseYear,
    ApplianceCondition? condition,
  }) {
    state = state.copyWith(
      categoryId: categoryId ?? state.categoryId,
      itemId: itemId ?? state.itemId,
      brand: brand ?? state.brand,
      model: model ?? state.model,
      purchaseYear: purchaseYear ?? state.purchaseYear,
      condition: condition ?? state.condition,
    );
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void setUserPrice(double price) {
    state = state.copyWith(userPriceVnd: price);
  }

  void setShippingPackage(ShippingPackageModel pkg) {
    state = state.copyWith(shippingPackage: pkg);
  }

  // Step 1: Upload photos & Init Post with AI Vision
  Future<bool> initPost() async {
    if (state.photos.length < 3) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn ít nhất 3 ảnh thiết bị');
      return false;
    }
    if (state.categoryId == null || state.categoryId!.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn Danh Mục Thiết Bị trước khi phân tích AI');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repo.initPost(
        photos: state.photos,
        categoryId: state.categoryId,
        itemId: state.itemId,
        itemCondition: state.condition.code,
        brand: state.brand,
        model: state.model,
      );

      final initialMessages = <AiChatMessageModel>[];
      if (res.initialMessage.isNotEmpty) {
        initialMessages.add(
          AiChatMessageModel(
            id: 'init-1',
            isUser: false,
            content: res.initialMessage,
            timestamp: DateTime.now(),
          ),
        );
      }

      state = state.copyWith(
        isLoading: false,
        postId: res.postId,
        aiSessionId: res.aiSessionId,
        suggestedQuestions: res.suggestedQuestions,
        chatMessages: initialMessages,
        description: (res.visualReport != null && res.visualReport!.isNotEmpty)
            ? res.visualReport!
            : state.description,
        step: 1, // Advance to AI Chat step
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Step 2: Chat with AI assistant
  Future<void> sendAiMessage(String text) async {
    if (text.trim().isEmpty || state.aiSessionId == null) return;

    final userMsg = AiChatMessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      chatMessages: [...state.chatMessages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final reply = await _repo.sendAiChat(
        sessionId: state.aiSessionId!,
        message: text.trim(),
      );

      final aiMsg = AiChatMessageModel(
        id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        content: reply.isNotEmpty ? reply : 'Đã ghi nhận thông tin của bạn.',
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        chatMessages: [...state.chatMessages, aiMsg],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Finalize AI Chat into complete product description
  Future<bool> finalizeDescription([String? extraNote]) async {
    if (state.aiSessionId == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final desc = await _repo.finalizeChat(
        sessionId: state.aiSessionId!,
        message: extraNote,
      );

      state = state.copyWith(
        isLoading: false,
        description: desc,
        step: 2, // Advance to Specs & Title step
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Step 3: Suggest SEO Title with AI
  Future<void> suggestTitle() async {
    if (state.postId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final title = await _repo.suggestTitle(
        postId: state.postId!,
        context: '${state.brand} ${state.model} ${state.condition.label}',
      );

      state = state.copyWith(
        isLoading: false,
        title: title.isNotEmpty ? title : state.title,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Step 4: AI Price Estimation (costs 1 valuation credit)
  Future<bool> estimatePrice() async {
    if (state.postId == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final est = await _repo.estimatePrice(postId: state.postId!);
      state = state.copyWith(
        isLoading: false,
        priceEstimation: est,
        userPriceVnd: est.estimatedPrice > 0 ? est.estimatedPrice : state.userPriceVnd,
      );

      // Refresh credits balance
      await ref.read(creditNotifierProvider.notifier).loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Step 6: Submit Post (costs 1 listing credit)
  Future<bool> submitPost() async {
    if (state.postId == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final submitData = {
        'title': state.title,
        'description': state.description,
        'price': state.userPriceVnd,
        'brand': state.brand,
        'model': state.model,
        'conditionGrade': state.condition.code,
        'shippingWeight': state.shippingPackage.weightGrams,
        'shippingLength': state.shippingPackage.lengthCm,
        'shippingWidth': state.shippingPackage.widthCm,
        'shippingHeight': state.shippingPackage.heightCm,
        'packageWeightGrams': state.shippingPackage.weightGrams,
        'packageLengthCm': state.shippingPackage.lengthCm,
        'packageWidthCm': state.shippingPackage.widthCm,
        'packageHeightCm': state.shippingPackage.heightCm,
      };

      await _repo.submitPost(postId: state.postId!, data: submitData);

      state = state.copyWith(isLoading: false, isSubmitted: true);

      // Refresh credits
      await ref.read(creditNotifierProvider.notifier).loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = CreateListingState(purchaseYear: DateTime.now().year);
  }
}

final createListingNotifierProvider =
    NotifierProvider<CreateListingNotifier, CreateListingState>(
        CreateListingNotifier.new);
