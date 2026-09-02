// =============================================================================
// CapMobile — API Swapp — Provider Info Tarif
// -----------------------------------------------------------------------------
// Fonctionnalité : État liste opérations tarifaires + sync FDS + filtre agenda.
// Design         : StateNotifier Riverpod — prêt pour branchement API.
// UI             : infoTarifProvider → InfoTarifPage (liste + sélection + date).
// Spécifications : [fetchOperations] utilise démo ; remplacer par
//                  SwappApiService.fetchInfoTarifs() quand endpoint prêt.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/swapp/models/info_tarif_item.dart';

import '../services/tarif_api_service.dart';
import 'tarif_api_provider.dart';

/// État écran Info Tarif.
class InfoTarifState {
  /// Liste complète (source API / démo).
  final List<InfoTarifItem> allOperations;

  /// Date agenda — filtre les opérations actives ce jour-là (null = toutes).
  final DateTime? filterDate;

  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSyncingFds;
  final String? error;

  const InfoTarifState({
    this.allOperations = const [],
    this.filterDate,
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSyncingFds = false,
    this.error,
  });

  /// Opérations visibles après filtre calendrier.
  List<InfoTarifItem> get visibleOperations {
    if (filterDate == null) return allOperations;
    return allOperations
        .where((op) => op.isActiveOn(filterDate!))
        .toList(growable: false);
  }

  /// true si toutes les opérations visibles sont sélectionnées.
  bool get allVisibleSelected {
    final visible = visibleOperations;
    if (visible.isEmpty) return false;
    return visible.every((op) => selectedIds.contains(op.id));
  }

  InfoTarifState copyWith({
    List<InfoTarifItem>? allOperations,
    DateTime? filterDate,
    bool clearFilterDate = false,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSyncingFds,
    String? error,
    bool clearError = false,
  }) {
    return InfoTarifState(
      allOperations: allOperations ?? this.allOperations,
      filterDate: clearFilterDate ? null : filterDate ?? this.filterDate,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSyncingFds: isSyncingFds ?? this.isSyncingFds,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Notifier — charge les opérations, filtre agenda, sélection multi.
class InfoTarifNotifier extends StateNotifier<InfoTarifState> {
  InfoTarifNotifier(this._service) : super(const InfoTarifState());

  final TarifApiService _service;

  /// Charge la liste des opérations (démo → API).
  Future<void> fetchOperations({int? codeMag}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _service.fetchOperations(codeMag: codeMag);
      state = state.copyWith(
        allOperations: items,
        isLoading: false,
        selectedIds: {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Filtre agenda — opérations actives à [date] ; null = afficher toutes.
  void setFilterDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearFilterDate: true);
      return;
    }
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(filterDate: normalized);
  }

  /// Bascule la sélection d'une opération (multi-sélection).
  void toggleSelection(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  /// Sélectionne toutes les opérations visibles ou désélectionne tout.
  void toggleSelectAllVisible() {
    final visible = state.visibleOperations;
    if (visible.isEmpty) return;

    if (state.allVisibleSelected) {
      final next = Set<String>.from(state.selectedIds);
      for (final op in visible) {
        next.remove(op.id);
      }
      state = state.copyWith(selectedIds: next);
    } else {
      final next = Set<String>.from(state.selectedIds)
        ..addAll(visible.map((op) => op.id));
      state = state.copyWith(selectedIds: next);
    }
  }

  /// Lance la mise à jour FDS sur le serveur puis recharge la liste.
  Future<void> syncFds({int? codeMag, required int codeCollab}) async {
    if (state.isSyncingFds) return;
    state = state.copyWith(isSyncingFds: true, clearError: true);
    try {
      await _service.updateFds(codeMag: codeMag, codeCollab: codeCollab);
      await fetchOperations(codeMag: codeMag);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      state = state.copyWith(isSyncingFds: false);
    }
  }
}

final infoTarifProvider =
    StateNotifierProvider<InfoTarifNotifier, InfoTarifState>((ref) {
      return InfoTarifNotifier(ref.watch(tarifApiServiceProvider));
    });
