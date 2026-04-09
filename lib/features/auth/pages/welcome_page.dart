import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../../home/pages/home_page.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ──────────────────────────────────────────────────────────────
class _AppColors {
  static const bg         = Color(0xFFDCF4F8);   // Gris très clair (fond de l'app)
  static const surface    = Color(0xFFFFFFFF);   // Blanc pur (cartes et inputs)
  static const surfaceAlt = Color(0xFFE5E7EB);   // Gris doux (zones secondaires)
  static const border     = Color(0xFFD1D5DB);   // Bordures nettes mais discrètes
  static const cyan       = Color(0xFF0070F3);   // Bleu "Electric" (plus lisible sur blanc)
  static const cyanDim    = Color(0xFF70A1FF);   // Bleu ciel (accent secondaire)
  static const cyanGlow   = Color(0x150070F3);   // Halo très léger pour les scans
  static const success    = Color(0xFF10B981);   // Vert émeraude (succès encodage)
  static const warning    = Color(0xFFF59E0B);   // Orange ambre (attention/chargement)
  static const error      = Color(0xFFEF4444);   // Rouge vif (erreur scan/api)
  static const textPrimary   = Color(0xFF111827); // Noir ardoise (lisibilité max)
  static const textSecondary = Color(0xFF4B5563); // Gris texte info
  static const textMuted     = Color(0xFF9CA3AF); // Gris désactivé
}
// ──────────────────────────────────────────────────────────────
//  PAGE PRINCIPALE
// ──────────────────────────────────────────────────────────────
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin {

  // ── Controllers texte / focus ──
  final _scanController = TextEditingController();
  final _scanFocusNode  = FocusNode();
  String _scanBuffer    = '';
  Timer? _scanTimer;
  Timer? _focusKeepAliveTimer;

  // ── State ──
  bool _scanMode = false;

  // ── Animation controllers ──
  late final AnimationController _entranceCtrl;   // apparition initiale
  late final AnimationController _pulseCtrl;      // halo pulsé icône
  late final AnimationController _scanRingCtrl;   // anneau scan actif
  late final AnimationController _shakeCtrl;      // shake erreur
  late final AnimationController _dotsCtrl;       // points de chargement
  late final AnimationController _gridCtrl;       // grille de fond

  // ── Animations dérivées ──
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _pulse;
  late final Animation<double> _scanRing;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupFocusListener();
    _setupMethodChannel();
    // Démarrer le scan automatiquement après l'animation d'entrée
    _entranceCtrl.forward().then((_) => _startScan());
  }

  void _setupFocusListener() {
    _scanFocusNode.addListener(() {
      if (_scanMode && !_scanFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scanMode) {
            _scanFocusNode.requestFocus();
          }
        });
      }
    });
  }

  void _initAnimations() {
    // --- Entrée (1 400 ms total) ---
    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, .3), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _titleFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, .2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    // --- Pulse logo (infini) ---
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: .6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // --- Anneau scan (infini) ---
    _scanRingCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    );
    _scanRing = CurvedAnimation(parent: _scanRingCtrl, curve: Curves.easeOut);

    // --- Shake erreur ---
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    // --- Points chargement ---
    _dotsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat();

    // --- Grille de fond ---
    _gridCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();
  }

  // ── Method Channel Zebra ──
  void _setupMethodChannel() {
    const MethodChannel('com.example.cap_mobile1/rfid')
        .setMethodCallHandler((call) async {
      if (call.method == 'onScanButton') {
        if (!_scanMode && !ref.read(authProvider).isLoading) {
          _startScan();
        }
      }
    });
  }

  void _startScan() {
    if (!mounted) return;
    setState(() {
      _scanMode   = true;
      _scanBuffer = '';
      _scanController.clear();
    });
    _scanRingCtrl.repeat();

    // Focus initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanFocusNode.requestFocus();
    });

    // Keep-alive : vérifier et reprendre le focus toutes les 2 secondes
    _focusKeepAliveTimer?.cancel();
    _focusKeepAliveTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) {
        if (mounted && _scanMode && !_scanFocusNode.hasFocus) {
          _scanFocusNode.requestFocus();
        }
      },
    );
  }

  void _onCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _focusKeepAliveTimer?.cancel();
    _scanRingCtrl.stop();
    setState(() => _scanMode = false);
    ref.read(authProvider.notifier).authenticate(trimmed);
  }

  void _triggerShake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  Timer? _scanTimer2;
  void _checkScanComplete() {
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 200), () {
      if (_scanBuffer.isNotEmpty) _onCodeScanned(_scanBuffer);
    });
  }

  @override
  void dispose() {
    _focusKeepAliveTimer?.cancel();
    _scanTimer?.cancel();
    _scanTimer2?.cancel();
    _scanController.dispose();
    _scanFocusNode.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _scanRingCtrl.dispose();
    _shakeCtrl.dispose();
    _dotsCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      if (next.error != null && previous?.error == null) {
        _triggerShake();
        // Relancer le scan après une erreur
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !ref.read(authProvider).isAuthenticated) _startScan();
        });
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _AppColors.bg,
        body: Stack(
          children: [
            // ── Grille de fond animée ──
            _buildAnimatedGrid(),

            // ── Champ invisible DataWedge ──
            if (_scanMode)
              Positioned(
                top: -100,
                child: SizedBox(
                  width: 1, height: 1,
                  child: TextField(
                    controller: _scanController,
                    focusNode: _scanFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    onChanged: (value) {
                      if (value.contains('\n') || value.contains('\r')) {
                        _onCodeScanned(value);
                      } else {
                        _scanBuffer = value;
                        _checkScanComplete();
                      }
                    },
                    onSubmitted: _onCodeScanned,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

            // ── Contenu principal ──
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              const Spacer(flex: 2),
                              _buildLogo(),
                              const SizedBox(height: 28),
                              _buildTitle(),
                              const Spacer(flex: 2),
                              _buildStatusCard(authState),
                              const SizedBox(height: 16),
                              _buildFooter(),
                              const Spacer(flex: 1),
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

  // ──────────────────────────────────────────────────────────────
  //  WIDGETS
  // ──────────────────────────────────────────────────────────────

  Widget _buildAnimatedGrid() {
    return AnimatedBuilder(
      animation: _gridCtrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(progress: _gridCtrl.value),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: SlideTransition(
        position: _logoSlide,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              // Halo externe
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.cyan.withOpacity(.04 * _pulse.value),
                ),
              ),
              // Halo interne
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.cyan.withOpacity(.08 * _pulse.value),
                ),
              ),
              // Icône principale
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _AppColors.cyan.withOpacity(.4 + .3 * _pulse.value),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.cyan.withOpacity(.2 * _pulse.value),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.nfc_rounded, size: 44, color: _AppColors.cyan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_AppColors.textPrimary, _AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'CAP MOBILE',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 1,
                  color: _AppColors.cyanDim.withOpacity(.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'GESTION RFID & ÉTIQUETAGE',
                  style: TextStyle(
                    fontSize: 11,
                    color: _AppColors.textSecondary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 1,
                  color: _AppColors.cyanDim.withOpacity(.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AuthState authState) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .1),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: authState.isLoading
              ? _buildLoadingCard()
              : authState.error != null
              ? _buildErrorCard(authState.error!)
              : _buildScanCard(),
        ),
      ),
    );
  }

  // ── Carte Scan ──
  Widget _buildScanCard() {
    return _GlassCard(
      key: const ValueKey('scan'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Anneau animé
          AnimatedBuilder(
            animation: _scanRing,
            builder: (_, __) => SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Anneau pulsé
                  if (_scanMode)
                    ...List.generate(2, (i) {
                      final delay = i * .5;
                      final v = (_scanRingCtrl.value - delay) % 1.0;
                      return Opacity(
                        opacity: (1 - v).clamp(0, 1),
                        child: Container(
                          width: 40 + 32 * v,
                          height: 40 + 32 * v,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _AppColors.cyan.withOpacity((1 - v) * .6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  // Icône centrale
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _AppColors.cyanGlow,
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.cyan.withOpacity(.5)),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _AppColors.cyan,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Scannez votre badge',
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pointez le scanner Zebra vers votre code-barres',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Barre de scan animée
          _AnimatedScanBar(),
        ],
      ),
    );
  }

  // ── Carte Chargement ──
  Widget _buildLoadingCard() {
    return _GlassCard(
      key: const ValueKey('loading'),
      accentColor: _AppColors.warning,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52, height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _AppColors.warning.withOpacity(.3),
                ),
              ),
              SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _AppColors.warning,
                ),
              ),
              const Icon(Icons.person_search_rounded,
                  color: _AppColors.warning, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Authentification en cours',
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _dotsCtrl,
            builder: (_, __) {
              final dots = '.' * ((_dotsCtrl.value * 3).floor() + 1);
              return Text(
                'Vérification des accréditations$dots',
                style: const TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 13,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Carte Erreur ──
  Widget _buildErrorCard(String error) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final dx = math.sin(_shake.value * math.pi * 6) * 6 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: _GlassCard(
        key: const ValueKey('error'),
        accentColor: _AppColors.error,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _AppColors.error.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.error.withOpacity(.4)),
              ),
              child: const Icon(Icons.badge_outlined,
                  color: _AppColors.error, size: 26),
            ),
            const SizedBox(height: 14),
            const Text(
              'Badge non reconnu',
              style: TextStyle(
                color: _AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AppColors.error.withOpacity(.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Relance du scan dans 2 secondes...',
              style: TextStyle(
                color: _AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 6, height: 6,
          decoration: const BoxDecoration(
            color: _AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Système Zebra connecté',
          style: TextStyle(
            color: _AppColors.textMuted,
            fontSize: 12,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  COMPOSANTS RÉUTILISABLES
// ──────────────────────────────────────────────────────────────

/// Carte en verre avec bordure colorée
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  const _GlassCard({
    Key? key,
    required this.child,
    this.accentColor = _AppColors.cyan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(.06),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Barre de scan qui défile de haut en bas
class _AnimatedScanBar extends StatefulWidget {
  @override
  State<_AnimatedScanBar> createState() => _AnimatedScanBarState();
}

class _AnimatedScanBarState extends State<_AnimatedScanBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          color: _AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _AppColors.border),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Stack(
            children: [
              // Lignes horizontales décoratives
              ...List.generate(3, (i) => Positioned(
                top: 8.0 + i * 10,
                left: 8, right: 8,
                child: Container(
                  height: 1,
                  color: _AppColors.textMuted.withOpacity(.3),
                ),
              )),
              // Ligne de scan qui défile
              Positioned(
                top: 2 + 32 * _anim.value,
                left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _AppColors.cyan,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.cyan.withOpacity(.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  PAINTER – Grille de fond techno
// ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(.04)
      ..strokeWidth = .6
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    final offset = (progress * spacing) % spacing;

    // Lignes horizontales
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Lignes verticales
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Points d'intersection lumineux aléatoires
    final dotPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(.12)
      ..style = PaintingStyle.fill;

    final rng = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = .8 + rng.nextDouble() * 1.2;
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
}