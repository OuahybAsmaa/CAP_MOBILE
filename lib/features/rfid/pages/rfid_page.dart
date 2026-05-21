import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../article/providers/article_provider.dart';
import '../providers/rfid_provider.dart';
import 'rfid_encoding_page.dart';
import 'rfid_constants.dart';
import 'rfid_control_tab.dart';
import '../../../core/services/datawedge_service.dart';

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

  // ── Tab Controller ──
  late TabController _tabController;

  // ── Scan article (DataWedge) ──
  StreamSubscription<String>? _scanSubscription;
  bool _articleScanMode = false;

  // ── State encodage ──
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

    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });

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
        await rfidNotifier.loadAvailableReaders();
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

    _initDataWedge();
  }

  void _initDataWedge() {
    _scanSubscription =
        ref.read(dataWedgeServiceProvider).onScan.listen((data) {
          if (mounted && _articleScanMode) {
            _onArticleCodeScanned(data);
          }
        });
  }

  void _checkReadyToScan() {
    final rfidState = ref.read(rfidProvider);
    final wasReady  = _readyToScan;
    _readyToScan    = rfidState.connectedReader != null && _headerValidated;
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
    setState(() => _articleScanMode = true);
    ref.read(articleProvider.notifier).clearArticle();
  }

  void _onArticleCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
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
        if (result is int) setState(() => _totalEncodedCount = result);
        _startArticleScan();
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _instructionCtrl.dispose();
    _headerFocusNode.dispose();
    _tabController.dispose();
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
        body: Column(
          children: [
            _buildHeader(),
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Encodage'),
                  Tab(text: 'Contrôle'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEncodingTab(rfidState, uniqueReaders, connected),
                  const RfidControlTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ONGLET ENCODAGE
  // ══════════════════════════════════════════════════════════════
  Widget _buildEncodingTab(
      RfidState rfidState, List uniqueReaders, connected) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStepCard(
            step: 1,
            title: 'Header étiquette vierge',
            child: _buildHeaderInput(),
          ),
          const SizedBox(height: 12),
          _buildInstructionCard(connected, rfidState.isLoading),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  WIDGETS COMMUNS
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final rfidState     = ref.watch(rfidProvider);
    final uniqueReaders = rfidState.availableReaders.toSet().toList();
    final connected     = rfidState.connectedReader;

    return Container(
      //height: 185,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 14),
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
                            color: Colors.white
                                .withOpacity(.15 + .05 * _pulseCtrl.value),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(.3)),
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
                            _tabController.index == 0
                                ? 'Encodage des puces'
                                : 'Contrôle qualité',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lecteur RFID',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: connected != null
                              ? Colors.green.withOpacity(.25)
                              : Colors.white.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: connected != null
                                ? Colors.greenAccent.withOpacity(.6)
                                : Colors.white.withOpacity(.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(
                                color: connected != null
                                    ? Colors.greenAccent
                                    : Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              connected != null ? 'Connecté' : 'Déconnecté',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: connected != null
                                    ? Colors.greenAccent
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: connected != null
                          ? AppColors.success.withOpacity(.06)
                          : Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: connected != null
                            ? AppColors.success
                            : Colors.white.withOpacity(.3),
                        width: connected != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connected != null
                              ? Icons.nfc_rounded
                              : Icons.nfc_outlined,
                          color: connected != null
                              ? AppColors.success
                              : Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: rfidState.isLoading && connected == null
                              ? const Row(children: [
                            SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text('Recherche...',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ])
                              : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: connected?.name,
                              isExpanded: true,
                              dropdownColor: AppColors.primaryDark,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white),
                              iconEnabledColor: Colors.white70,
                              hint: Text(
                                uniqueReaders.isEmpty
                                    ? 'Aucun lecteur'
                                    : 'Choisir un lecteur',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10),
                              ),
                              items: uniqueReaders
                                  .map((r) => DropdownMenuItem<String>(
                                value: r.name,
                                child: Text(r.name,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white)),
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
                                : () => ref
                                .read(rfidProvider.notifier)
                                .disconnectReader(),
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
                              : () => ref
                              .read(rfidProvider.notifier)
                              .loadAvailableReaders(),
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              const Icon(Icons.tag_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                    _headerOptions.contains(_header) ? _header : null,
                    isExpanded: true,
                    hint: const Text(
                      'Choisir un header',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    items: _headerOptions
                        .map((h) => DropdownMenuItem<String>(
                      value: h,
                      child: Text(h,
                          style: const TextStyle(fontSize: 11)),
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