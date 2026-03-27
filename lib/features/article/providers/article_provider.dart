import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/article_service.dart';
import '../models/article_model.dart';

// ─── État ─────────────────────────────────────────────────────────────────────

class ArticleState {
  final ArticleModel? article;
  final bool isLoading;
  final String? error;

  const ArticleState({
    this.article,
    this.isLoading = false,
    this.error,
  });

  ArticleState copyWith({
    ArticleModel? article,
    bool? isLoading,
    String? error,
    bool clearArticle = false,
    bool clearError   = false,
  }) {
    return ArticleState(
      article:   clearArticle ? null : article   ?? this.article,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError  ? null : error      ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ArticleNotifier extends StateNotifier<ArticleState> {
  final ArticleService _articleService;

  ArticleNotifier(this._articleService) : super(const ArticleState());

  /// Appelé quand DataWedge scanne un code article
  Future<void> fetchArticle(String codeItem) async {
    final code = codeItem.trim();
    if (code.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true, clearArticle: true);
      final article = await _articleService.getArticle(code);
      state = state.copyWith(article: article, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error:     e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  void clearArticle() {
    state = const ArticleState();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final articleServiceProvider =
Provider<ArticleService>((ref) => ArticleService());

final articleProvider =
StateNotifierProvider<ArticleNotifier, ArticleState>((ref) {
  final service = ref.watch(articleServiceProvider);
  return ArticleNotifier(service);
});