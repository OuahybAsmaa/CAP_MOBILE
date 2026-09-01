import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/utils/swapp_scan_flow.dart';
import 'package:cap_mobile/swapp/widgets/article_code_dialog.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ecran obligatoire avant la fiche produit : attend un scan Zebra ou camera.
class ProduitScanPage extends ConsumerStatefulWidget {
  const ProduitScanPage({super.key});

  static Route<void> fadeRoute() => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const ProduitScanPage(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );

  @override
  ConsumerState<ProduitScanPage> createState() => _ProduitScanPageState();
}

class _ProduitScanPageState extends ConsumerState<ProduitScanPage>
    with SingleTickerProviderStateMixin {
  final _dataWedge = SwappDataWedgeListener();
  bool _processing = false;
  late final AnimationController _scanAnimation;

  int get _codeMag => SwappApiConstants.resolveCodeMagFromCollab(
    ref.read(authProvider).collaborateur,
  );

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(swappProductProvider.notifier).clear();
      await _dataWedge.start(ref: ref, onScan: _openProductFromCode);
    });
  }

  Future<void> _openProductFromCode(String rawCode) async {
    final code = rawCode.trim();
    if (!mounted || code.isEmpty || _processing) return;
    setState(() => _processing = true);

    final loaded = await processSwappProductScanUi(
      context: context,
      ref: ref,
      code: code,
      codeMag: _codeMag,
    );

    if (!mounted) return;
    setState(() => _processing = false);
    if (!loaded) return;

    await Navigator.pushReplacement(
      context,
      DetailProduitPage.fadeRoute(loadDefaultProduct: false),
    );
  }

  Future<void> _openCamera() async {
    if (_processing) return;
    _dataWedge.pause();
    try {
      final code = await openQrCameraScanner(context, context.l10n);
      if (mounted && code != null) await _openProductFromCode(code);
    } finally {
      _dataWedge.resume();
    }
  }

  Future<void> _openCodeDialog() async {
    if (_processing || !mounted) return;
    final code = await showArticleCodeDialog(context, initialCode: '');
    if (!mounted || code == null || code.trim().isEmpty) return;
    await _openProductFromCode(code);
  }

  @override
  void dispose() {
    _dataWedge.dispose();
    _scanAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // Le clavier appartient au dialogue de saisie superpose. La page de
        // scan en arriere-plan ne doit pas se contracter, sinon sa carte
        // verticale deborde pendant l'ouverture du clavier.
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            Container(
              height: top + 64,
              padding: EdgeInsets.only(top: top),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    'Produit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardHeight = (constraints.maxHeight - 20).clamp(
                    400.0,
                    500.0,
                  ).toDouble();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          final pulse = 1 +
                              .012 *
                                  (1 -
                                      (2 * _scanAnimation.value - 1).abs());
                          return Transform.scale(scale: pulse, child: child);
                        },
                        child: Container(
                          width: double.infinity,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF58D4D2), Color(0xFF079CC7)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF079CC7,
                                ).withValues(alpha: 0.24),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _ScanDotsPainter(),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 220,
                                    height: 190,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _ScanRings(animation: _scanAnimation),
                                        AnimatedBuilder(
                                          animation: _scanAnimation,
                                          builder: (context, child) {
                                            final value = _scanAnimation.value;
                                            final scale =
                                                1 +
                                                .045 *
                                                    (1 -
                                                        (2 * value - 1).abs());
                                            return Transform.scale(
                                              scale: scale,
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            width: 108,
                                            height: 108,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF007E9F)
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 7),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.qr_code_scanner_rounded,
                                              size: 52,
                                              color: Color(0xFF19B9C4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Scannez une référence',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Placez le code-barres dans le cadre\npour rechercher un produit',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.24),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.28),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF007A9E)
                                              .withValues(alpha: 0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'Caméra ou lecteur Zebra',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  FilledButton.icon(
                                    onPressed: _processing ? null : _openCamera,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF008FB7),
                                      disabledBackgroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 16,
                                      ),
                                      elevation: 7,
                                      shadowColor: const Color(0xFF006F99),
                                      shape: const StadiumBorder(
                                        side: BorderSide(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    icon: _processing
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.bolt_rounded),
                                    label: Text(
                                      _processing
                                          ? 'Recherche…'
                                          : 'Scanner maintenant',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _processing
                                        ? null
                                        : _openCodeDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white54,
                                      side: const BorderSide(
                                        color: Colors.white70,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 13,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_alt_outlined,
                                    ),
                                    label: const Text(
                                      'Saisir le code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanRings extends StatelessWidget {
  const _ScanRings({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => SizedBox(
        width: 190,
        height: 190,
        child: CustomPaint(painter: _ScanRingsPainter(animation.value)),
      ),
    );
  }
}

class _ScanDotsPainter extends CustomPainter {
  const _ScanDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    const spacing = 7.0;
    const radius = 1.15;

    void drawCorner({required bool right, required bool bottom}) {
      for (var row = 0; row < 8; row++) {
        for (var column = 0; column < 8; column++) {
          if (row + column > 10) continue;
          final x = right
              ? size.width - 18 - column * spacing
              : 18 + column * spacing;
          final y = bottom
              ? size.height - 18 - row * spacing
              : 18 + row * spacing;
          canvas.drawCircle(Offset(x, y), radius, paint);
        }
      }
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _ScanDotsPainter oldDelegate) => false;
}

class _ScanRingsPainter extends CustomPainter {
  const _ScanRingsPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = size.center(Offset.zero);
    for (var index = 0; index < 4; index++) {
      final phase = (progress + index * .25) % 1;
      final radius = 45 + phase * 48;
      paint.color = Colors.white.withValues(alpha: .16 * (1 - phase));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
