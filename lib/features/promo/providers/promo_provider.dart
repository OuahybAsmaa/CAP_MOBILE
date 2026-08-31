import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promo_model.dart';
import '../../../core/services/promo_service.dart';
import '../../../core/services/article_service.dart';
import '../../../features/article/models/article_model.dart';
import 'package:flutter/material.dart';

// ── State ─────────────────────────────────────────────────────

class PromoState {
  final List<OperationCommerciale> operations;
  final Set<int> selectedOps;
  final bool isLoadingOps;
  final bool isLoadingPromo;
  final String? scannedGencode;
  final List<PromoResult>? promoResults;
  final ArticleModel? article;
  final DateTimeRange? dateFilter;
  final String? error;

  const PromoState({
    this.operations    = const [],
    this.selectedOps   = const {},
    this.isLoadingOps  = false,
    this.isLoadingPromo = false,
    this.scannedGencode,
    this.promoResults,
    this.article,
    this.dateFilter,
    this.error,
  });

  bool get hasResults => promoResults != null;

  // Liste filtrée par date
  List<OperationCommerciale> get filteredOperations {
    if (dateFilter == null) return operations;
    return operations.where((op) {
      return op.dateDebut.isBefore(dateFilter!.end.add(const Duration(days: 1))) &&
          op.dateFin.isAfter(dateFilter!.start.subtract(const Duration(days: 1)));
    }).toList();
  }

  PromoState copyWith({
    List<OperationCommerciale>? operations,
    Set<int>? selectedOps,
    bool? isLoadingOps,
    bool? isLoadingPromo,
    String? scannedGencode,
    List<PromoResult>? promoResults,
    ArticleModel? article,
    DateTimeRange? dateFilter,
    bool clearGencode  = false,
    String? error,
    bool clearError   = false,
    bool clearResults = false,
    bool clearDateFilter = false,
  }) => PromoState(
    operations:     operations     ?? this.operations,
    selectedOps:    selectedOps    ?? this.selectedOps,
    isLoadingOps:   isLoadingOps   ?? this.isLoadingOps,
    isLoadingPromo: isLoadingPromo ?? this.isLoadingPromo,
    scannedGencode: clearGencode   ? null : scannedGencode ?? this.scannedGencode,
    promoResults:   clearResults   ? null : promoResults ?? this.promoResults,
    article:        clearResults   ? null : article ?? this.article,
    dateFilter:     clearDateFilter ? null : dateFilter ?? this.dateFilter,
    error:          clearError     ? null : error ?? this.error,
  );
}

// ── Notifier ──────────────────────────────────────────────────

class PromoNotifier extends StateNotifier<PromoState> {
  final PromoService _service;
  final ArticleService _articleService;
  final int codeMag;

  PromoNotifier(this._service, this._articleService, this.codeMag)
      : super(const PromoState());

  Future<void> loadOperations() async {
    state = state.copyWith(isLoadingOps: true, clearError: true);
    try {
      final ops = await _service.getOperations(codeMag);
      state = state.copyWith(
        operations: ops,
        isLoadingOps: false,
        selectedOps: ops.map((o) => o.codePromo).toSet(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingOps: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void toggleOperation(int codePromo) {
    final current = Set<int>.from(state.selectedOps);
    if (current.contains(codePromo)) {
      current.remove(codePromo);
    } else {
      current.add(codePromo);
    }
    state = state.copyWith(selectedOps: current);
  }

  void selectAll() {
    final all = state.operations.map((o) => o.codePromo).toSet();
    state = state.copyWith(selectedOps: all);
  }

  void deselectAll() {
    state = state.copyWith(selectedOps: {});
  }
  void setDateFilter(DateTimeRange range) {
    state = state.copyWith(dateFilter: range);
  }

  void clearDateFilter() {
    state = state.copyWith(clearDateFilter: true);
  }
  Future<void> verifierGencode(String gencode) async {
    final trimmed = gencode.trim();
    if (trimmed.isEmpty) return;
    if (state.selectedOps.isEmpty) return;

    state = state.copyWith(
      isLoadingPromo: true,
      scannedGencode: trimmed,
      clearResults: true,
      clearError: true,
    );

    try {
      // On lance les deux requêtes en parallèle
      final results = await _service.verifierPromo(
        gencode: int.parse(trimmed),
        codeMag: codeMag,
        listOp: state.selectedOps.toList(),
      );

      ArticleModel? article;
      try {
        article = await _articleService.getArticle(trimmed);
      } catch (_) {
        article = null;
      }

      state = state.copyWith(
        isLoadingPromo: false,
        promoResults: results,
        article: article,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPromo: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> majFds(int codeCollab) async {
    try {
      final message = await _service.majFds(codeMag: codeMag, codeCollab: codeCollab);
      await loadOperations();
      return message;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  void resetScan() {
    state = state.copyWith(clearResults: true, clearError: true ,clearGencode: true,);
  }

  void reset() {
    state = const PromoState();
  }
}

// ── Providers ─────────────────────────────────────────────────

final promoServiceProvider   = Provider<PromoService>((ref) => PromoService());
final articleServiceProvider = Provider<ArticleService>((ref) => ArticleService());

final promoProvider = StateNotifierProvider<PromoNotifier, PromoState>((ref) {
  return PromoNotifier(
    ref.watch(promoServiceProvider),
    ref.watch(articleServiceProvider),
    433,
  );
});

final operationModelesProvider =
FutureProvider.family<List<ModeleProduit>, int>((ref, codePromo) async {
  final service = ref.watch(promoServiceProvider);
  return service.getModelesOperation(codeMag: 433, codePromo: codePromo);
});