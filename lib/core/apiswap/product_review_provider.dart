// =============================================================================
// CapMobile — API Swapp — Provider avis produit (Riverpod)
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/product_review_item.dart';
import 'swapp_api_service.dart';
import 'swapp_product_provider.dart';

class ProductReviewState {
  final List<ProductReviewItem> reviews;
  final bool isLoading;
  final String? error;
  final String? loadedKey;

  const ProductReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.loadedKey,
  });

  ProductReviewState copyWith({
    List<ProductReviewItem>? reviews,
    bool? isLoading,
    String? error,
    String? loadedKey,
    bool clearError = false,
    bool clearData = false,
  }) {
    return ProductReviewState(
      reviews: clearData ? const [] : reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      loadedKey: clearData ? null : loadedKey ?? this.loadedKey,
    );
  }
}

class ProductReviewNotifier extends StateNotifier<ProductReviewState> {
  ProductReviewNotifier(this._service) : super(const ProductReviewState());

  final SwappApiService _service;

  Future<void> fetchReviews({
    required String codeArticle,
    required int codeCollab,
    bool force = false,
  }) async {
    final article = codeArticle.trim();
    if (article.isEmpty || codeCollab <= 0) return;

    final key = '$article/$codeCollab';
    if (!force &&
        state.loadedKey == key &&
        !state.isLoading &&
        (state.reviews.isNotEmpty || state.error == null)) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final reviews = await _service.fetchProductReviews(
        codeArticle: article,
        codeCollab: codeCollab,
      );
      reviews.sort((a, b) {
        final ad = a.dateReview;
        final bd = b.dateReview;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      state = state.copyWith(
        reviews: reviews,
        isLoading: false,
        loadedKey: key,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const ProductReviewState();
  }
}

final productReviewProvider =
    StateNotifierProvider<ProductReviewNotifier, ProductReviewState>((ref) {
  final service = ref.watch(swappApiServiceProvider);
  return ProductReviewNotifier(service);
});
