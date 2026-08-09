// =============================================================================
// CapMobile — Module Swapp — Flux scan (DataWedge + caméra)
// -----------------------------------------------------------------------------
// Fonctionnalité : Écoute scanner Zebra ; dialogue chargement ; feedback UI.
// Design         : Pause DataWedge pendant scan caméra pour éviter double traitement.
// UI             : Scan hardware → recharge hero+tableau ; scan caméra/QR idem ;
//                  processSwappProductScanUi → Dialog loading + SnackBar erreur.
// Spécifications : [SwappDataWedgeListener] lifecycle ; [processSwappProductScanUi]
//                  avec SnackBar erreur et haptic feedback.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'dart:async';

import 'package:cap_mobile/core/apiswap/swapp_product_provider.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/services/datawedge_service.dart';
import 'package:cap_mobile/features/article/providers/article_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'swapp_scan_handler.dart';

/// Initialise DataWedge et écoute les scans hardware (Zebra TC53E).
class SwappDataWedgeListener {
  StreamSubscription<String>? _subscription;
  bool _ready = false;
  bool _paused = false;
  bool _processing = false;

  bool get isReady => _ready;

  /// Démarre l'écoute ; [onScan] reçoit le code brut du trigger.
  Future<void> start({
    required WidgetRef ref,
    required Future<void> Function(String code) onScan,
  }) async {
    await _subscription?.cancel();

    final service = ref.read(dataWedgeServiceProvider);
    await service.initialize();
    _ready = true;

    _subscription = service.onScan.listen((data) async {
      if (_paused || _processing) return;
      final trimmed = data.trim();
      if (trimmed.isEmpty) return;

      _processing = true;
      try {
        await onScan(trimmed);
      } finally {
        _processing = false;
      }
    });
  }

  /// Suspendre pendant ouverture scanner caméra.
  void pause() => _paused = true;

  /// Reprendre après fermeture scanner caméra.
  void resume() => _paused = false;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _ready = false;
  }
}

/// Traite un code scanné (DataWedge ou caméra) avec appel API Swapp + UI.
Future<void> processSwappProductScanUi({
  required BuildContext context,
  required WidgetRef ref,
  required String code,
  bool showLoadingDialog = true,
  int? codeMag,
  VoidCallback? onProductLoaded,
}) async {
  if (!context.mounted) return;

  if (showLoadingDialog) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.scanLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  try {
    HapticFeedback.mediumImpact();
    await handleSwappProductScan(ref, code, codeMag: codeMag);

    if (!context.mounted) return;
    onProductLoaded?.call();
    final articleError = ref.read(articleProvider).error;
    final productError = ref.read(swappProductProvider).error;
    final error = productError ?? articleError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  } finally {
    if (showLoadingDialog && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
