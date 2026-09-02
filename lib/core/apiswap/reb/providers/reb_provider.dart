import 'package:cap_mobile/swapp/models/reb/reb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reb_api_service.dart';

class RebState {
  final List<RebItem> items;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const RebState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  RebState copyWith({
    List<RebItem>? items,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) => RebState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : error ?? this.error,
  );
}

class RebNotifier extends StateNotifier<RebState> {
  RebNotifier(this._service) : super(const RebState());
  final RebApiService _service;

  Future<void> fetchRebs({
    required int codeMag,
    DateTime? du,
    DateTime? au,
    bool enAttente = true,
    bool reset = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _service.fetchRebs(
        codeMag: codeMag,
        du: du,
        au: au,
        enAttente: enAttente,
      )
        ..sort(RebItem.compareRecent);
      final preserved = reset
          ? const <RebItem>[]
          : state.items
                .where(
                  (item) => enAttente
                      ? item.statut != RebStatut.enAttente
                      : item.statut != RebStatut.traitee,
                )
                .toList(growable: false);
      final merged = [...preserved, ...items]..sort(RebItem.compareRecent);
      state = state.copyWith(items: merged, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<List<RebEncaissementItem>> fetchEncaissements({
    required int codeMag,
    required DateTime date,
  }) => _service.fetchEncaissements(codeMag: codeMag, date: date);

  Future<RebItem?> createReb(RebCreateRequest request) async {
    if (state.isSaving) return null;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await _service.createReb(request);
      final updated = [created, ...state.items]..sort(RebItem.compareRecent);
      state = state.copyWith(items: updated, isSaving: false);
      return created;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void markAsTraitee(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(statut: RebStatut.traitee) else item,
      ],
    );
    // TODO(API): PATCH /api/rebs/{id}/statut.
  }

  /// Remplace la ligne en attente par la remise finalisée créée par le
  /// formulaire, sans conserver de doublon dans la liste locale.
  void completePending(String pendingId, RebItem created) {
    final completed = created.copyWith(statut: RebStatut.traitee);
    final updated = state.items
        .where((item) => item.id != pendingId && item.id != created.id)
        .toList(growable: true)
      ..add(completed)
      ..sort(RebItem.compareRecent);
    state = state.copyWith(items: updated);
  }
}

final rebApiServiceProvider = Provider<RebApiService>((ref) => RebApiService());
final rebProvider = StateNotifierProvider<RebNotifier, RebState>(
  (ref) => RebNotifier(ref.watch(rebApiServiceProvider)),
);
