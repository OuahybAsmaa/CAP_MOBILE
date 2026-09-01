// =============================================================================
// CapMobile — API Swapp — Provider Info Transfert
// -----------------------------------------------------------------------------
// Fonctionnalité : État fiche transfert vers un magasin destination.
// Design         : StateNotifier Riverpod — prêt pour branchement API.
// UI             : infoTransfertProvider → InfoTransfertDetailPage.
// Spécifications : [fetchFiche] utilise démo ; remplacer par
//                  SwappApiService.fetchInfoTransfert() quand endpoint prêt.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/swapp/models/info_transfert_item.dart';

import '../services/transfert_api_service.dart';
import 'transfert_api_provider.dart';

class InfoTransfertState {
  final InfoTransfertFiche? fiche;
  final bool isLoading;
  final String? error;

  const InfoTransfertState({this.fiche, this.isLoading = false, this.error});

  InfoTransfertState copyWith({
    InfoTransfertFiche? fiche,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearFiche = false,
  }) {
    return InfoTransfertState(
      fiche: clearFiche ? null : fiche ?? this.fiche,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class InfoTransfertNotifier extends StateNotifier<InfoTransfertState> {
  InfoTransfertNotifier(this._service) : super(const InfoTransfertState());

  final TransfertApiService _service;

  Future<void> fetchFiche({
    required int codeMagDest,
    String? nomMagDest,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO(API) : remplacer par _service.fetchInfoTransfert(codeMagDest: ...)
      await Future<void>.delayed(const Duration(milliseconds: 280));
      final fiche = await _service.fetchFiche(
        codeMagDest,
        nomMagDest: nomMagDest,
      );
      state = state.copyWith(fiche: fiche, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final infoTransfertProvider =
    StateNotifierProvider<InfoTransfertNotifier, InfoTransfertState>((ref) {
      return InfoTransfertNotifier(ref.watch(transfertApiServiceProvider));
    });
