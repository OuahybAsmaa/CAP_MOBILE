import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qc_model.dart';
import '../../../core/services/qc_service.dart';
import '../../../core/services/inventory_service.dart';

// ── Enum mode de contrôle ─────────────────────────────────────

enum QcControlMode { partiel, full }

// ── Résultat par pointure ─────────────────────────────────────

class QcTailleResult {
  final String pointure;
  final int qteAttendue;
  final int qteLue;
  // true = OK, false = manque, null = pas encore scanné
  bool get isOk => qteLue >= qteAttendue;

  const QcTailleResult({
    required this.pointure,
    required this.qteAttendue,
    required this.qteLue,
  });

  QcTailleResult copyWith({int? qteLue}) => QcTailleResult(
    pointure:    pointure,
    qteAttendue: qteAttendue,
    qteLue:      qteLue ?? this.qteLue,
  );
}

// ── Résultat par colis ────────────────────────────────────────

class QcColisResult {
  final QcColis colis;
  final List<QcTailleResult> tailleResults;
  final bool isComplete;
  final bool isRunning;

  const QcColisResult({
    required this.colis,
    required this.tailleResults,
    this.isComplete = false,
    this.isRunning  = false,
  });

  int get totalAttendu => tailleResults.fold(0, (s, t) => s + t.qteAttendue);
  int get totalLu      => tailleResults.fold(0, (s, t) => s + t.qteLue);
  bool get isAllOk     => tailleResults.every((t) => t.isOk);

  QcColisResult copyWith({
    List<QcTailleResult>? tailleResults,
    bool? isComplete,
    bool? isRunning,
  }) => QcColisResult(
    colis:         colis,
    tailleResults: tailleResults ?? this.tailleResults,
    isComplete:    isComplete    ?? this.isComplete,
    isRunning:     isRunning     ?? this.isRunning,
  );
}

// ── État global ───────────────────────────────────────────────

class QcState {
  final String?            scannedGencode;
  final String?            codeMod;
  final QcProductionModel? production;


  final QcControlMode?     selectedMode;
  final QcColis?           selectedColis;


  final List<QcColisResult> colisResults;
  final int                 currentColisIndex;
  final bool                isInventoryRunning;

  // UI
  final bool    isLoadingArticle;
  final bool    isLoadingColis;
  final bool    isLoadingGtin;   // pendant résolution GTIN→codeMod
  final String? error;

  final bool inventoryStarted;

  const QcState({
    this.scannedGencode,
    this.codeMod,
    this.production,
    this.selectedMode,
    this.selectedColis,
    this.colisResults         = const [],
    this.currentColisIndex    = 0,
    this.isInventoryRunning   = false,
    this.isLoadingArticle     = false,
    this.isLoadingColis       = false,
    this.isLoadingGtin        = false,
    this.inventoryStarted = false,
    this.error,
  });

  bool get isLoading => isLoadingArticle || isLoadingColis;

  // Colis en cours d'inventaire
  QcColisResult? get currentColisResult =>
      colisResults.isEmpty ? null : colisResults[currentColisIndex];

  QcState copyWith({
    String?            scannedGencode,
    String?            codeMod,
    QcProductionModel? production,
    QcControlMode?     selectedMode,
    QcColis?           selectedColis,
    List<QcColisResult>? colisResults,
    int?               currentColisIndex,
    bool?              isInventoryRunning,
    bool?              isLoadingArticle,
    bool?              isLoadingColis,
    bool?              isLoadingGtin,
    bool?              inventoryStarted,
    String?            error,
    bool clearError      = false,
    bool clearProduction = false,
    bool clearSelectedColis = false,
  }) => QcState(
    scannedGencode:     scannedGencode     ?? this.scannedGencode,
    codeMod:            codeMod            ?? this.codeMod,
    production:         clearProduction    ? null : production ?? this.production,
    selectedMode:       selectedMode       ?? this.selectedMode,
    selectedColis:      clearSelectedColis ? null : selectedColis ?? this.selectedColis,
    colisResults:       colisResults       ?? this.colisResults,
    currentColisIndex:  currentColisIndex  ?? this.currentColisIndex,
    isInventoryRunning: isInventoryRunning ?? this.isInventoryRunning,
    isLoadingArticle:   isLoadingArticle   ?? this.isLoadingArticle,
    isLoadingColis:     isLoadingColis     ?? this.isLoadingColis,
    isLoadingGtin:      isLoadingGtin      ?? this.isLoadingGtin,
    inventoryStarted: inventoryStarted ?? this.inventoryStarted,
    error:              clearError         ? null : error ?? this.error,
  );

  QcState reset() => const QcState();
}

// ── Notifier ──────────────────────────────────────────────────

class QcNotifier extends StateNotifier<QcState> {
  final QcService       _qcService;
  final InventoryService _inventoryService;

  StreamSubscription? _tagSubscription;

  // EPCs déjà traités (pour éviter les doublons)
  final Set<String> _processedEpcs = {};

  QcNotifier(this._qcService, this._inventoryService)
      : super(const QcState());

  // ─────────────────────────────────────────────
  //  ÉTAPE 1 : scan gencode → codeMod → colis
  // ─────────────────────────────────────────────

  Future<void> onGencodeScanned(String gencode) async {
    final code = gencode.trim();
    if (code.isEmpty) return;

    state = QcState(
      scannedGencode:  code,
      isLoadingArticle: true,
    );

    try {
      // gencode → codeMod
      final codeMod = await _qcService.getCodeModFromGencode(code);
      state = state.copyWith(
        codeMod:          codeMod,
        isLoadingArticle: false,
        isLoadingColis:   true,
      );

      // codeMod → liste colis
      final production = await _qcService.getColisByCodeMod(codeMod);
      state = state.copyWith(
        production:     production,
        isLoadingColis: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingArticle: false,
        isLoadingColis:   false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  ÉTAPE 2 : choix du mode
  // ─────────────────────────────────────────────

  void selectMode(QcControlMode mode) {
    state = state.copyWith(selectedMode: mode);
  }

  // Partiel : sélection d'un colis précis
  void selectColis(QcColis colis) {
    state = state.copyWith(selectedColis: colis);
    // Préparer les résultats pour ce colis
    final results = [_buildColisResult(colis)];
    state = state.copyWith(
      colisResults:      results,
      currentColisIndex: 0,
    );
  }

  void resetInventory() {
    _tagSubscription?.cancel();
    _tagSubscription = null;
    _processedEpcs.clear();

    // Remet les qteLue à 0 pour tous les colis
    final resetResults = state.colisResults.map((cr) {
      final tailleReset = cr.tailleResults
          .map((t) => t.copyWith(qteLue: 0))
          .toList();
      return cr.copyWith(
        tailleResults: tailleReset,
        isComplete: false,
        isRunning: false,
      );
    }).toList();

    state = state.copyWith(
      isInventoryRunning: false,
      inventoryStarted: false,
      currentColisIndex: 0,
      colisResults: resetResults,
    );
  }
  // Full : prépare tous les colis
  void prepareFullControl() {
    final production = state.production;
    if (production == null) return;

    // Fusionner toutes les tailles de tous les assortiments
    final Map<String, int> tailleMap = {};
    for (final colis in production.colis) {
      for (final taille in colis.tailles) {
        tailleMap[taille.taille] = (tailleMap[taille.taille] ?? 0) + (taille.qte * colis.nbCol);
      }
    }

    // Trier les tailles numériquement
    final tailles = tailleMap.entries
        .map((e) => QcTaille(taille: e.key, qte: e.value))
        .toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.taille) ?? 0;
        final bNum = int.tryParse(b.taille) ?? 0;
        return aNum.compareTo(bNum);
      });

    // Colis virtuel unique représentant tout l'article
    final colisVirtuel = QcColis(
      codeColis:   'FULL CONTROL',
      nbCol:       production.colis.fold(0, (sum, c) => sum + c.nbCol),
      nbArt:       production.colis.fold(0, (sum, c) => sum + c.nbArt),
      supCommande: '',
      codeSaison:  '',
      pcb:         0,
      long:        0,
      larg:        0,
      haut:        0,
      img:         '',
      tailles:     tailles,
    );

    state = state.copyWith(
      colisResults:      [_buildColisResult(colisVirtuel)],
      currentColisIndex: 0,
      inventoryStarted:  false,
      isInventoryRunning: false,
    );
  }

  QcColisResult _buildColisResult(QcColis colis) {
    final tailleResults = colis.tailles.map((t) => QcTailleResult(
      pointure:    t.taille,
      qteAttendue: t.qte,
      qteLue:      0,
    )).toList();
    return QcColisResult(colis: colis, tailleResults: tailleResults);
  }

  // ─────────────────────────────────────────────
  //  ÉTAPE 3 : inventaire RFID
  // ─────────────────────────────────────────────

  Future<void> startInventory() async {
    if (state.isInventoryRunning) return;

    _processedEpcs.clear();

    // Marquer le colis courant comme "en cours"
    final updatedResults = List<QcColisResult>.from(state.colisResults);
    updatedResults[state.currentColisIndex] =
        updatedResults[state.currentColisIndex].copyWith(isRunning: true);

    state = state.copyWith(
      isInventoryRunning: true,
      inventoryStarted:   true,
      colisResults: updatedResults,
      clearError: true,
    );

    // Écouter le stream de tags
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

    // Marquer le colis courant comme terminé
    final updatedResults = List<QcColisResult>.from(state.colisResults);
    updatedResults[state.currentColisIndex] =
        updatedResults[state.currentColisIndex].copyWith(
          isRunning:  false,
          isComplete: true,
        );

    state = state.copyWith(
      isInventoryRunning: false,
      colisResults: updatedResults,
    );
  }

  // Passer au colis suivant (full control)
  Future<void> nextColis() async {
    final nextIndex = state.currentColisIndex + 1;
    if (nextIndex >= state.colisResults.length) return;

    _processedEpcs.clear();
    state = state.copyWith(
      currentColisIndex: nextIndex,
      inventoryStarted:  false,
    );
  }

  // ─────────────────────────────────────────────
  //  TRAITEMENT D'UN TAG RFID
  // ─────────────────────────────────────────────

  Future<void> _onTagReceived(String epc) async {
    if (!state.isInventoryRunning) return;
    if (_processedEpcs.contains(epc)) return;
    _processedEpcs.add(epc);

    print('=== TAG REÇU: $epc ===');

    if (epc.toUpperCase().startsWith('3034')) {
      print('IGNORÉ: puce vierge');
      return;
    }

    final gtin = _extractGtinFromEpc(epc);
    print('GTIN: $gtin');
    if (gtin == null) return;

    try {
      final article = await _qcService.getArticleByGtin(gtin);
      print('ARTICLE: codeMod=${article?.codeMod} libTaille=${article?.libTaille}');
      print('ATTENDU: codeMod=${state.codeMod}');

      if (article == null) {
        print('IGNORÉ: article null');
        return;
      }
      if (article.codeMod != state.codeMod) {
        print('IGNORÉ: codeMod différent');
        return;
      }

      final pointure = _extractPointure(article.libTaille);
      print('POINTURE: $pointure');
      print('POINTURES COLIS: ${state.currentColisResult?.tailleResults.map((t) => '${t.pointure}(${t.qteLue}/${t.qteAttendue})').toList()}');

      if (pointure == null) return;
      _incrementTaille(pointure);
      print('✓ INCRÉMENTÉ: $pointure');

    } catch (e) {
      print('ERREUR: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  EXTRACTION GTIN DEPUIS EPC
  // ─────────────────────────────────────────────
  String? _extractGtinFromEpc(String epc) {
    try {
      final binary = epc.split('').map((c) =>
          int.parse(c, radix: 16).toRadixString(2).padLeft(4, '0')
      ).join();

      if (binary.length < 96) return null;

      final companyBin = binary.substring(14, 34);
      final sg1Bin     = binary.substring(34, 58);

      final company = int.parse(companyBin, radix: 2)
          .toString().padLeft(6, '0');
      final sg1 = int.parse(sg1Bin, radix: 2)
          .toString().padLeft(6, '0');

      // Reconstruit 13 chiffres sans le chiffre de contrôle
      final gtinSans13 = '0$company$sg1';  // = "0361758079782" (13 chiffres)

      // Calcul du chiffre de contrôle EAN-14
      final checkDigit = _calcCheckDigit(gtinSans13);

      final gtin = '$gtinSans13$checkDigit'; // = "03617580797823"
      print('GTIN reconstruit: $gtin');
      return gtin;

    } catch (_) {
      return null;
    }
  }

// Calcul chiffre de contrôle EAN standard
  int _calcCheckDigit(String partialGtin) {
    int sum = 0;
    for (int i = 0; i < partialGtin.length; i++) {
      final digit = int.parse(partialGtin[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }


  String? _extractPointure(String libTaille) {
    final match = RegExp(r'\d+').firstMatch(libTaille);
    return match?.group(0);
  }

  // ─────────────────────────────────────────────
  //  INCRÉMENTER LA QUANTITÉ LUE POUR UNE POINTURE
  // ─────────────────────────────────────────────

  void _incrementTaille(String pointure) {
    final colisResults = List<QcColisResult>.from(state.colisResults);
    final colisResult  = colisResults[state.currentColisIndex];
    final tailleResults = List<QcTailleResult>.from(colisResult.tailleResults);

    final idx = tailleResults.indexWhere((t) => t.pointure == pointure);
    if (idx == -1) return;

    tailleResults[idx] = tailleResults[idx].copyWith(
      qteLue: tailleResults[idx].qteLue + 1,
    );

    colisResults[state.currentColisIndex] = colisResult.copyWith(
      tailleResults: tailleResults,
    );

    state = state.copyWith(colisResults: colisResults);

    // ── Arrêt automatique si tout est conforme ──
    final updated = colisResults[state.currentColisIndex];
    final allOk = updated.tailleResults.every((t) => t.qteLue >= t.qteAttendue);
    if (allOk && state.isInventoryRunning) {
      print('CONTRÔLE CONFORME — arrêt automatique');
      stopInventory();
    }
  }

  // ─────────────────────────────────────────────
  //  RESET
  // ─────────────────────────────────────────────

  void reset() {
    _tagSubscription?.cancel();
    _tagSubscription = null;
    _processedEpcs.clear();
    state = const QcState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _tagSubscription?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────

final qcServiceProvider =
Provider<QcService>((ref) => QcService());

final qcInventoryServiceProvider =
Provider<InventoryService>((ref) => InventoryService());

final qcProvider =
StateNotifierProvider<QcNotifier, QcState>((ref) {
  return QcNotifier(
    ref.watch(qcServiceProvider),
    ref.watch(qcInventoryServiceProvider),
  );
});