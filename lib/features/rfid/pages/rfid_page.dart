import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/rfid_service.dart';
import '../../article/providers/article_provider.dart';
import '../providers/rfid_provider.dart';
import 'rfid_encoding_page.dart';
import 'rfid_constants.dart';

// ──────────────────────────────────────────────────────────────
//  RFID PAGE
// ──────────────────────────────────────────────────────────────
class RfidPage extends ConsumerStatefulWidget {
  const RfidPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RfidPage> createState() => _RfidPageState();
}

class _RfidPageState extends ConsumerState<RfidPage>
    with TickerProviderStateMixin {

  // ── Scan article (DataWedge) ──
  final _articleScanController = TextEditingController();
  final _articleFocusNode      = FocusNode();
  bool   _articleScanMode      = false;
  String _scanBuffer           = '';
  Timer? _scanTimer;
  Timer? _focusKeepAliveTimer;

  // ── State ──
  // Mode encodage fixe — plus de sélection
  late final RfidMode _selectedMode;
  bool _readyToScan = false;
  int _totalEncodedCount = 0;
  String _header = '3034';
  static const _headerOptions = ['3034', '3035'];
  final _headerController = TextEditingController(text: '3034');
  bool _headerValidated = true;
  final _headerFocusNode = FocusNode();

  // ── Animations ──
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _instructionCtrl;

  @override
  void initState() {
    super.initState();

    // Encodage est le seul mode — on le fixe d'emblée
    _selectedMode = rfidModes.firstWhere((m) => m.id == 'encoding');

    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _instructionCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rfidNotifier = ref.read(rfidProvider.notifier);
      final rfidState    = ref.read(rfidProvider);

      if (rfidState.connectedReader == null) {
        // 1. Charger les lecteurs disponibles
        await rfidNotifier.loadAvailableReaders();

        // 2. Connecter automatiquement au premier lecteur trouvé
        final updatedState = ref.read(rfidProvider);
        if (updatedState.availableReaders.isNotEmpty &&
            updatedState.connectedReader == null) {
          rfidNotifier.connectToReader(updatedState.availableReaders.first);
        }
      }

      rfidNotifier.clearScannedTag();
      ref.read(rfidServiceProvider).reinitHandler();
    });

    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = () {
      if (_readyToScan && !_articleScanMode) {
        _startArticleScan();
      }
    };

    _setupFocusListener();
  }

  void _setupFocusListener() {
    _articleFocusNode.addListener(() {
      if (_articleScanMode && !_articleFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _articleScanMode) _articleFocusNode.requestFocus();
        });
      }
    });
  }

  void _checkReadyToScan() {
    final rfidState = ref.read(rfidProvider);
    final wasReady = _readyToScan;
    // Plus besoin de vérifier _selectedMode (toujours défini)
    _readyToScan = rfidState.connectedReader != null && _headerValidated;
    if (_readyToScan && !wasReady) {
      _instructionCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _readyToScan) _startArticleScan();
      });
    }
  }

  void _startArticleScan() {
    if (!mounted) return;

    _headerFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_readyToScan) return;
      setState(() {
        _articleScanMode = true;
        _scanBuffer      = '';
        _articleScanController.clear();
      });
      ref.read(articleProvider.notifier).clearArticle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _articleFocusNode.requestFocus();
      });
      _focusKeepAliveTimer?.cancel();
      _focusKeepAliveTimer = Timer.periodic(
          const Duration(seconds: 2), (_) {
        if (mounted && _articleScanMode && !_articleFocusNode.hasFocus) {
          _articleFocusNode.requestFocus();
        }
      });
    });
  }

  void _onArticleCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _focusKeepAliveTimer?.cancel();
    setState(() => _articleScanMode = false);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RfidEncodingPage(
          mode: _selectedMode,
          initialCode: trimmed,
          initialEncodedCount: _totalEncodedCount,
          header: _header,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((result) {
      if (mounted) {
        if (result is int) {
          setState(() => _totalEncodedCount = result);
        }
        _startArticleScan();
      }
    });
  }

  void _checkScanComplete() {
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 200), () {
      if (_scanBuffer.isNotEmpty) {
        _onArticleCodeScanned(_scanBuffer);
        _scanBuffer = '';
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _focusKeepAliveTimer?.cancel();
    _articleScanController.dispose();
    _articleFocusNode.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _instructionCtrl.dispose();
    _headerFocusNode.dispose();
    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rfidState = ref.watch(rfidProvider);

    ref.listen<RfidState>(rfidProvider, (_, __) {
      if (mounted) _checkReadyToScan();
    });

    final uniqueReaders = rfidState.availableReaders.toSet().toList();
    final connected     = rfidState.connectedReader;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            // ── Champ DataWedge invisible ──
            if (_articleScanMode)
              Positioned(
                top: -100,
                child: SizedBox(
                  width: 1, height: 1,
                  child: TextField(
                    controller: _articleScanController,
                    focusNode: _articleFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.none,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    onSubmitted: _onArticleCodeScanned,
                    onChanged: (val) {
                      if (val.contains('\n') || val.contains('\r')) {
                        _onArticleCodeScanned(val.trim());
                      } else {
                        _scanBuffer = val;
                        _checkScanComplete();
                      }
                    },
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),

            // ── Contenu sans scroll ──
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            // Étape 1 — Lecteur RFID (inchangée)
                            _buildStepCard(
                              step: 1,
                              title: 'Lecteur RFID',
                              child: _buildReaderSelector(rfidState, uniqueReaders, connected),
                            ),
                            const SizedBox(height: 8),
                            // Étape 2
                            _buildStepCard(
                              step: 2,
                              title: 'Header étiquette vierge',
                              child: _buildHeaderInput(),
                            ),
                            const SizedBox(height: 12),
                            _buildInstructionCard(connected, rfidState.isLoading),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header
  Widget _buildHeader() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 14,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15 + .05 * _pulseCtrl.value),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(.3),
                        ),
                      ),
                      child: const Icon(Icons.nfc_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Service RFID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        'Encodage des puces',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte étape
  Widget _buildStepCard({
    required int step,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  // ── Sélecteur lecteur
  Widget _buildReaderSelector(RfidState rfidState, List uniqueReaders, connected) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: connected != null
                ? AppColors.success.withOpacity(.06)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: connected != null ? AppColors.success : AppColors.border,
              width: connected != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                connected != null ? Icons.nfc_rounded : Icons.nfc_outlined,
                color: connected != null ? AppColors.success : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: rfidState.isLoading && connected == null
                    ? Row(children: [
                  const SizedBox(
                    width: 10, height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Recherche...',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ])
                    : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: connected?.name,
                    isExpanded: true,
                    hint: Text(
                      uniqueReaders.isEmpty
                          ? 'Aucun lecteur'
                          : 'Choisir un lecteur',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    items: uniqueReaders
                        .map((r) => DropdownMenuItem<String>(
                      value: r.name,
                      child: Text(r.name,
                          style: const TextStyle(fontSize: 10)),
                    ))
                        .toList(),
                    onChanged: rfidState.isLoading
                        ? null
                        : (name) {
                      if (name == null) return;
                      final reader = uniqueReaders
                          .firstWhere((r) => r.name == name);
                      if (connected != null) {
                        ref
                            .read(rfidProvider.notifier)
                            .disconnectReader();
                      }
                      ref
                          .read(rfidProvider.notifier)
                          .connectToReader(reader);
                    },
                  ),
                ),
              ),
              if (connected != null)
                GestureDetector(
                  onTap: rfidState.isLoading
                      ? null
                      : () => ref.read(rfidProvider.notifier).disconnectReader(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Déco',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: rfidState.isLoading
                    ? null
                    : () {
                  ref.read(rfidProvider.notifier).loadAvailableReaders();
                },
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary, size: 12),
                ),
              ),
            ],
          ),
        ),
        if (connected != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Connecté à ${connected.name}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _headerValidated
                ? AppColors.success.withOpacity(.06)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _headerValidated ? AppColors.success : AppColors.border,
              width: _headerValidated ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.tag_rounded, color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _headerOptions.contains(_header) ? _header : null,
                    isExpanded: true,
                    hint: const Text(
                      'Choisir un header',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    items: _headerOptions
                        .map((h) => DropdownMenuItem<String>(
                      value: h,
                      child: Text(
                        h,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _header          = val;
                        _headerValidated = true;
                      });
                      _headerController.text = val;
                      _headerFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                      _checkReadyToScan();
                    },
                  ),
                ),
              ),
              if (_headerValidated)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
            ],
          ),
        ),
        if (_headerValidated)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 10),
                const SizedBox(width: 3),
                Text(
                  'Header validé : $_header',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Carte instruction
  Widget _buildInstructionCard(connected, bool isLoading) {
    if (!_readyToScan) {
      return _InstructionCard(
        icon: Icons.touch_app_rounded,
        iconColor: AppColors.textMuted,
        bgColor: const Color(0xFFF8FAFC),
        borderColor: AppColors.border,
        title: 'Configuration requise',
        lines: const [
          '① Connectez un lecteur RFID',
          '② Validez le header',
          '③ Scan démarre automatiquement',
        ],
        lineColor: AppColors.textSecondary,
      );
    }

    return FadeTransition(
      opacity: _instructionCtrl,
      child: _InstructionCard(
        icon: Icons.qr_code_scanner_rounded,
        iconColor: AppColors.primary,
        bgColor: AppColors.primarySoft,
        borderColor: AppColors.primary.withOpacity(.25),
        title: 'Prêt — scannez le code article',
        lines: const [
          '✓ Lecteur RFID connecté',
          '✓ Header validé',
          '→ Pointez le scanner vers le code-barres',
        ],
        lineColor: AppColors.primary,
        animated: true,
        pulseCtrl: _pulseCtrl,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  INSTRUCTION CARD
// ──────────────────────────────────────────────────────────────
class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final List<String> lines;
  final Color lineColor;
  final bool animated;
  final Animation<double>? pulseCtrl;

  const _InstructionCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.lines,
    required this.lineColor,
    this.animated = false,
    this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              animated && pulseCtrl != null
                  ? AnimatedBuilder(
                animation: pulseCtrl!,
                builder: (_, __) => Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(.1 + .06 * pulseCtrl!.value),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              )
                  : Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: lineColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 10,
                      color: lineColor.withOpacity(.8),
                      height: 1.2,
                      fontWeight: line.startsWith('→')
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}