// =============================================================================
// CapMobile — Module Swapp — Scanner QR / codes-barres caméra
// -----------------------------------------------------------------------------
// Fonctionnalité : Scan via mobile_scanner (QR, EAN, Code128…) ; même flux que DataWedge.
// Design         : Plein écran noir ; cadre blanc 260×260 ; torche ; hint en bas.
// UI             : Route fullscreenDialog — AppBar bleu + preview caméra ;
//                  cadre blanc centre ; hint bas ; torche AppBar actions.
// Spécifications : [openQrCameraScanner] demande permission caméra puis push route ;
//                  retourne code scanné ou null ; formats multiples supportés.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/debug/agent_debug_log.dart';
import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Point d'entrée — permission caméra puis navigation vers [QrCameraScannerPage].
Future<String?> openQrCameraScanner(
  BuildContext context,
  AppLocalizations l10n,
) async {
  // #region agent log
  AgentDebugLog.log(
    location: 'qr_camera_scanner_page.dart:openQrCameraScanner',
    message: 'open scanner requested',
    hypothesisId: 'A',
  );
  // #endregion

  final status = await Permission.camera.request();
  if (!status.isGranted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cameraPermissionDenied)),
      );
    }
    return null;
  }

  if (!context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AppLocalizationsScope(
        l10n: l10n,
        child: const QrCameraScannerPage(),
      ),
    ),
  );
}

/// Page scanner — MobileScannerController, détection unique, torche toggle.
class QrCameraScannerPage extends StatefulWidget {
  const QrCameraScannerPage({super.key});

  @override
  State<QrCameraScannerPage> createState() => _QrCameraScannerPageState();
}

class _QrCameraScannerPageState extends State<QrCameraScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _handled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // #region agent log
    AgentDebugLog.log(
      location: 'qr_camera_scanner_page.dart:initState',
      message: 'scanner page init',
      hypothesisId: 'B',
      data: {'autoStart': true},
    );
    // #endregion
  }

  @override
  void dispose() {
    // #region agent log
    AgentDebugLog.log(
      location: 'qr_camera_scanner_page.dart:dispose',
      message: 'scanner page dispose',
      hypothesisId: 'D',
    );
    // #endregion
    _controller.dispose();
    super.dispose();
  }

  String? _readBarcode(Barcode barcode) {
    final raw = barcode.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) return raw;

    final display = barcode.displayValue?.trim();
    if (display != null && display.isNotEmpty) return display;

    final url = barcode.url?.url.trim();
    if (url != null && url.isNotEmpty) return url;

    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;

    for (final barcode in capture.barcodes) {
      final value = _readBarcode(barcode);
      if (value == null || value.isEmpty) continue;

      _handled = true;
      HapticFeedback.mediumImpact();
      // #region agent log
      AgentDebugLog.log(
        location: 'qr_camera_scanner_page.dart:_onDetect',
        message: 'barcode detected',
        hypothesisId: 'B',
        data: {'length': value.length},
      );
      // #endregion
      Navigator.of(context).pop(value);
      return;
    }
  }

  void _onDetectError(Object error, StackTrace stackTrace) {
    // #region agent log
    AgentDebugLog.log(
      location: 'qr_camera_scanner_page.dart:_onDetectError',
      message: error.toString(),
      hypothesisId: 'A',
      data: {'type': error.runtimeType.toString()},
    );
    // #endregion
    if (!mounted) return;
    setState(() => _errorMessage = error.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.scanQrTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (!state.isInitialized) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.scanTorch,
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            onDetectError: _onDetectError,
            errorBuilder: (context, error) {
              // #region agent log
              AgentDebugLog.log(
                location: 'qr_camera_scanner_page.dart:errorBuilder',
                message: error.errorCode.name,
                hypothesisId: 'A',
                data: {
                  'details': error.errorDetails?.message,
                },
              );
              // #endregion
              return _CameraErrorView(
                message: error.errorDetails?.message ?? l10n.cameraOpenFailed,
                onRetry: () {
                  setState(() => _errorMessage = null);
                },
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_errorMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text(
                l10n.scanQrHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue erreur caméra — message + bouton Retry.
class _CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
