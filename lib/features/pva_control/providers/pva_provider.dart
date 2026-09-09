import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pva_model.dart';
import '../../../core/services/pva_service.dart';
import '../../../core/services/inventory_service.dart';

// ─────────────────────────────────────────────────────────────
//  ÉTAT GLOBAL — Contrôle Support (PVA)
// ─────────────────────────────────────────────────────────────

class PvaState {
  final String?              scannedCode;
  final PvaReceptionModel?   reception;
  final bool                 isLoadingRecep;

  final List<PvaLigneResult> ligneResults;
  final bool                 isInventoryRunning;
  final bool                 inventoryStarted;

  final String? error;

  const PvaState({
    this.scannedCode,
    this.reception,
    this.isLoadingRecep     = false,
    this.ligneResults       = const [],
    this.isInventoryRunning = false,
    this.inventoryStarted   = false,
    this.error,
  });

  int get totalAttendu => ligneResults.fold(0, (s, l) => s + l.ligne.qte);
  int get totalLu      => ligneResults.fold(0, (s, l) => s + l.qteLue);
  bool get isAllOk     => ligneResults.isNotEmpty &&
      ligneResults.every((l) => l.isOk);

  Map<String, int> get _gtinIndex {
    final map = <String, int>{};
    for (var i = 0; i < ligneResults.length; i++) {
      map[ligneResults[i].ligne.gtin] = i;
    }
    return map;
  }

  PvaState copyWith({
    String?              scannedCode,
    PvaReceptionModel?   reception,
    bool?                isLoadingRecep,
    List<PvaLigneResult>? ligneResults,
    bool?                isInventoryRunning,
    bool?                inventoryStarted,
    String?              error,
    bool                 clearError     = false,
    bool                 clearReception = false,
  }) => PvaState(
    scannedCode:        scannedCode        ?? this.scannedCode,
    reception:          clearReception ? null : reception ?? this.reception,
    isLoadingRecep:     isLoadingRecep     ?? this.isLoadingRecep,
    ligneResults:       ligneResults       ?? this.ligneResults,
    isInventoryRunning: isInventoryRunning ?? this.isInventoryRunning,
    inventoryStarted:   inventoryStarted   ?? this.inventoryStarted,
    error:              clearError ? null : error ?? this.error,
  );

  PvaState reset() => const PvaState();
}

// ─────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────

class PvaNotifier extends StateNotifier<PvaState> {
  final PvaService       _pvaService;
  final InventoryService _inventoryService;

  StreamSubscription? _tagSubscription;
  final Set<String>   _processedEpcs = {};

  Map<String, int> _gtinIndex = {};

  PvaNotifier(this._pvaService, this._inventoryService)
      : super(const PvaState());

  // ─────────────────────────────────────────────
  //  ÉTAPE 1 : scan code support → API
  // ─────────────────────────────────────────────

  Future<void> onCodeScanned(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    state = PvaState(
      scannedCode:    trimmed,
      isLoadingRecep: true,
    );

    try {
      final reception = await _pvaService.getReception(trimmed);

      final ligneResults = reception.lignes
          .map((l) => PvaLigneResult(ligne: l, qteLue: 0))
          .toList();

      state = state.copyWith(
        reception:      reception,
        ligneResults:   ligneResults,
        isLoadingRecep: false,
        clearError:     true,
      );
      _gtinIndex = state._gtinIndex;

      final enriched = await Future.wait(
        ligneResults.map((lr) async {
          final codeMod = await _pvaService.getCodeModFromEan(lr.ligne.ean);
          return PvaLigneResult(
            ligne:  lr.ligne.withCodeMod(codeMod),
            qteLue: lr.qteLue,
          );
        }),
      );

      state = state.copyWith(ligneResults: enriched);

    } catch (e) {
      state = state.copyWith(
        isLoadingRecep: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  ÉTAPE 2 : inventaire RFID
  // ─────────────────────────────────────────────

  Future<void> startInventory() async {
    if (state.isInventoryRunning) return;

    _processedEpcs.clear();

    state = state.copyWith(
      isInventoryRunning: true,
      inventoryStarted:   true,
      clearError:         true,
    );

    _tagSubscription = _inventoryService.tagStream.listen(
          (event) {
        if (event is Map && event['event'] == 'tag') {
          _onTagReceived(event['tagId'] as String);
        }
      },
      onError: (e) {
        state = state.copyWith(
          isInventoryRunning: false,
          error: 'Erreur stream: $e',
        );
      },
    );

    try {
      await _inventoryService.startInventory();
    } catch (e) {
      await stopInventory();
      state = state.copyWith(
        isInventoryRunning: false,
        error: 'Erreur démarrage inventaire: $e',
      );
    }
  }

  Future<void> stopInventory() async {
    if (!state.isInventoryRunning) return;

    await _tagSubscription?.cancel();
    _tagSubscription = null;

    try { await _inventoryService.stopInventory(); } catch (_) {}

    state = state.copyWith(isInventoryRunning: false);
  }

  void resetInventory() {
    _tagSubscription?.cancel();
    _tagSubscription = null;
    _processedEpcs.clear();

    final reset = state.ligneResults
        .map((l) => l.copyWith(qteLue: 0))
        .toList();

    state = state.copyWith(
      ligneResults:       reset,
      isInventoryRunning: false,
      inventoryStarted:   false,
    );
  }

  // ─────────────────────────────────────────────
  //  TRAITEMENT TAG RFID
  // ─────────────────────────────────────────────

  Future<void> _onTagReceived(String epc) async {
    if (!state.isInventoryRunning)    return;
    if (_processedEpcs.contains(epc)) return;
    _processedEpcs.add(epc);

    if (epc.toUpperCase().startsWith('3034')) return;

    final gtin = _extractGtinFromEpc(epc);
    if (gtin == null) return;

    // Chercher d'abord dans l'index local (sans appel API)
    if (_gtinIndex.containsKey(gtin)) {
      _incrementLigne(_gtinIndex[gtin]!);
      return;
    }

    // Fallback : matching direct sur gtin/ean des lignes (comme le code PVA d'origine)
    final idx = state.ligneResults.indexWhere(
          (l) => l.ligne.gtin == gtin || epc.contains(l.ligne.ean),
    );
    if (idx == -1) return;

    _incrementLigne(idx);
  }

  void _incrementLigne(int idx) {
    final results = List<PvaLigneResult>.from(state.ligneResults);
    results[idx] = results[idx].copyWith(qteLue: results[idx].qteLue + 1);
    state = state.copyWith(ligneResults: results);

    // Arrêt automatique si tout est conforme
    if (results.every((l) => l.isOk)) {
      stopInventory();
    }
  }

  // ─────────────────────────────────────────────
  //  EXTRACTION GTIN DEPUIS EPC (identique QC/EXP)
  // ─────────────────────────────────────────────

  String? _extractGtinFromEpc(String epc) {
    try {
      final binary = epc.split('').map((c) =>
          int.parse(c, radix: 16).toRadixString(2).padLeft(4, '0')
      ).join();

      if (binary.length < 96) return null;

      final company = int.parse(binary.substring(14, 34), radix: 2)
          .toString().padLeft(6, '0');
      final sg1 = int.parse(binary.substring(34, 58), radix: 2)
          .toString().padLeft(6, '0');

      final gtinSans13 = '0$company$sg1';
      final checkDigit = _calcCheckDigit(gtinSans13);
      return '$gtinSans13$checkDigit';
    } catch (_) {
      return null;
    }
  }

  int _calcCheckDigit(String partial) {
    int sum = 0;
    for (int i = 0; i < partial.length; i++) {
      final d = int.parse(partial[i]);
      sum += (i % 2 == 0) ? d * 3 : d;
    }
    return (10 - (sum % 10)) % 10;
  }

  // ─────────────────────────────────────────────
  //  RESET COMPLET
  // ─────────────────────────────────────────────

  void reset() {
    _tagSubscription?.cancel();
    _tagSubscription = null;
    _processedEpcs.clear();
    _gtinIndex = {};
    state = const PvaState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _tagSubscription?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────────

final pvaServiceProvider =
Provider<PvaService>((ref) => PvaService());

final pvaInventoryServiceProvider =
Provider<InventoryService>((ref) => InventoryService());

final pvaProvider =
StateNotifierProvider<PvaNotifier, PvaState>((ref) => PvaNotifier(
  ref.watch(pvaServiceProvider),
  ref.watch(pvaInventoryServiceProvider),
));