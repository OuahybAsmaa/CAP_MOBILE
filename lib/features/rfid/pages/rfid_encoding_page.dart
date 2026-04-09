import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/rfid_service.dart';
import '../../../core/services/rfid_sse_service.dart';
import '../../article/models/article_model.dart';
import '../../article/providers/article_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/rfid_provider.dart';
import '../utils/epc_calculator.dart';
import 'rfid_constants.dart';
import '../../SSE/pages/rfid_sse_list_page.dart';

// ──────────────────────────────────────────────────────────────
//  MODÈLE LOCAL — entrée SSE de la session courante
// ──────────────────────────────────────────────────────────────
class SseSessionEntry {
  final String epc;
  final String serial;
  final String gencode;
  final String libArticle;
  final String marque;
  final String libTaille;
  final String libColoris;
  final String codeMod;
  final String prixFormate;
  final DateTime dateHeure;

  const SseSessionEntry({
    required this.epc,
    required this.serial,
    required this.gencode,
    required this.libArticle,
    required this.marque,
    required this.libTaille,
    required this.libColoris,
    required this.codeMod,
    required this.prixFormate,
    required this.dateHeure,
  });
}

// ──────────────────────────────────────────────────────────────
//  RFID ENCODING PAGE
// ──────────────────────────────────────────────────────────────
class RfidEncodingPage extends ConsumerStatefulWidget {
  final RfidMode mode;
  final String initialCode;
  final int initialEncodedCount;
  final String header;
  final List<SseSessionEntry> initialSseEntries;

  const RfidEncodingPage({
    Key? key,
    required this.mode,
    required this.initialCode,
    this.initialEncodedCount = 0,
    this.header = '3034',
    this.initialSseEntries = const [],
  }) : super(key: key);

  @override
  ConsumerState<RfidEncodingPage> createState() => _RfidEncodingPageState();
}

class _RfidEncodingPageState extends ConsumerState<RfidEncodingPage>
    with TickerProviderStateMixin {

  // ── EPC state ──
  String? _factoryEpc;
  String? _newEpc;
  String? _error;
  bool    _isProcessing = false;
  bool    _isBlocked    = false;
  bool    _successShown = false;
  int     _encodedCount = 0;

  // ── DataWedge — rescan article depuis cette page ──
  final _articleScanController = TextEditingController();
  final _articleFocusNode      = FocusNode();
  bool   _articleScanMode      = false;
  String _scanBuffer           = '';
  Timer? _scanTimer;
  Timer? _focusKeepAliveTimer;

  // ── Liste des encodages de la session ──
  late final List<SseSessionEntry> _sseEntries;

  // ── Animations ──
  late final AnimationController _articleEntranceCtrl;
  late final AnimationController _encodingEntranceCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _counterCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _scanRingCtrl;

  @override
  void initState() {
    super.initState();

    _encodedCount = widget.initialEncodedCount;
    _sseEntries   = List<SseSessionEntry>.from(widget.initialSseEntries);

    _articleEntranceCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _encodingEntranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _successCtrl          = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _counterCtrl          = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeCtrl            = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scanRingCtrl         = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articleProvider.notifier).fetchArticle(widget.initialCode);
    });

    // Focus listener — garde le focus DataWedge actif
    _articleFocusNode.addListener(() {
      if (_articleScanMode && !_articleFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _articleScanMode) _articleFocusNode.requestFocus();
        });
      }
    });

    // ── Bouton latéral Zebra ──
    // DataWedge est déjà pré-activé après chaque succès,
    // donc le bouton encode simplement la puce quand on est en attente
    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = () {
      if (!_articleScanMode &&
          ref.read(articleProvider).article != null &&
          !_isProcessing &&
          !_isBlocked &&
          !_successShown) {
        _scanAndWrite();
      }
    };
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _focusKeepAliveTimer?.cancel();
    _articleScanController.dispose();
    _articleFocusNode.dispose();
    _articleEntranceCtrl.dispose();
    _encodingEntranceCtrl.dispose();
    _successCtrl.dispose();
    _counterCtrl.dispose();
    _shakeCtrl.dispose();
    _scanRingCtrl.dispose();
    ref.read(rfidServiceProvider).onScanButtonPressed = null;
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  LOGIQUE : scan + écriture + POST SSE
  // ──────────────────────────────────────────────────────────────
  Future<void> _scanAndWrite() async {
    final article    = ref.read(articleProvider).article;
    final rfidState  = ref.read(rfidProvider);
    final codeCollab = ref.read(authProvider).collaborateur?.codeCollab ?? 0;

    if (article == null ||
        rfidState.connectedReader == null ||
        _isProcessing ||
        _isBlocked) return;

    setState(() {
      _isProcessing = true;
      _isBlocked    = false;
      _error        = null;
      _factoryEpc   = null;
      _newEpc       = null;
      _successShown = false;
    });

    try {
      // Étape 1 — Lire l'EPC usine
      await ref.read(rfidProvider.notifier).readSingleTag();
      final epc = ref.read(rfidProvider).lastScannedTag;

      if (epc == null || epc.isEmpty) {
        _showError('Aucun tag détecté.\nVérifiez que la puce est bien positionnée\nsur le lecteur et réessayez.');
        return;
      }

      // Étape 2 — Vérifier puce vierge
      if (!epc.toUpperCase().startsWith(widget.header.toUpperCase())) {
        _showError('Puce déjà encodée !\nEPC détecté : $epc\nUtilisez une puce vierge.');
        return;
      }

      // Étape 3 — Calculer le nouvel EPC
      final serial = EpcCalculator.extractSerialFromEpc(epc);
      final newEpc = EpcCalculator.buildEpcFromGtin(article.gtin, serial);

      setState(() { _factoryEpc = epc; _newEpc = newEpc; });
      _encodingEntranceCtrl.forward(from: 0);

      // Étape 4 — Écrire dans la puce
      await ref.read(rfidProvider.notifier).writeTag(tagId: epc, data: newEpc);

      // Étape 5 — POST SSE (non bloquant si échec)
      _postSse(
        serial:     serial,
        gencode:    article.gencode,
        newEpc:     newEpc,
        codeCollab: codeCollab,
        article:    article,
      );

      // Succès
      setState(() {
        _successShown = true;
        _encodedCount++;
        _isProcessing = false;
        _isBlocked    = false;
      });
      _successCtrl.forward(from: 0);
      _counterCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();

      // ── Pré-activer DataWedge immédiatement après le succès ──
      // Ainsi le prochain appui Zebra scanne et charge l'article en une seule action
      _startArticleScan();

    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  // ── POST SSE — fire and forget ──
  Future<void> _postSse({
    required String serial,
    required String gencode,
    required String newEpc,
    required int codeCollab,
    required ArticleModel article,
  }) async {
    try {
      final ok = await RfidSseService().addRfidSse(
        gencodeRfid: serial,
        gencodeCh:   gencode,
        epc:         newEpc,
        codeCollab:  codeCollab,
        codeMag:     400,
        codeMotif:   '8',
      );
      if (ok && mounted) {
        setState(() {
          _sseEntries.insert(0, SseSessionEntry(
            epc:         newEpc,
            serial:      serial,
            gencode:     gencode,
            libArticle:  article.libArticle,
            marque:      article.marque,
            libTaille:   article.libTaille,
            libColoris:  article.libColoris,
            codeMod:     article.codeMod,
            prixFormate: article.prixFormate,
            dateHeure:   DateTime.now(),
          ));
        });
      }
    } catch (e) {
      debugPrint('⚠️ POST SSE échoué (non bloquant): $e');
    }
  }

  // ── Afficher erreur + bloquer ──
  void _showError(String msg) {
    setState(() {
      _error        = msg;
      _isProcessing = false;
      _isBlocked    = true; // bloque jusqu'à ce que l'user appuie sur Réessayer
    });
    _shakeCtrl.reset();
    _shakeCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  // ── Reset + lance le scan du prochain article ──
  void _resetForNextTag() {
    setState(() {
      _factoryEpc   = null;
      _newEpc       = null;
      _error        = null;
      _successShown = false;
      _isProcessing = false;
      _isBlocked    = false;
    });
    _encodingEntranceCtrl.reset();
    _successCtrl.reset();
  }

  void _openSseList() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RfidSseListPage(entries: _sseEntries),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  DATAWEDGE — rescan article dans cette page
  // ──────────────────────────────────────────────────────────────

  /// Active le mode scan article (champ invisible DataWedge)
  void _startArticleScan() {
    if (!mounted) return;
    setState(() {
      _articleScanMode = true;
      _scanBuffer      = '';
      _articleScanController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleFocusNode.requestFocus();
    });
    _focusKeepAliveTimer?.cancel();
    _focusKeepAliveTimer = Timer.periodic(
      const Duration(seconds: 2), (_) {
      if (mounted && _articleScanMode && !_articleFocusNode.hasFocus) {
        _articleFocusNode.requestFocus();
      }
    },
    );
  }

  /// Appelé quand DataWedge envoie un code article
  void _onArticleCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _focusKeepAliveTimer?.cancel();
    setState(() { _articleScanMode = false; });

    // Reset zone encodage + charger le nouvel article
    _resetForNextTag();
    ref.read(articleProvider.notifier).fetchArticle(trimmed);
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

  // ──────────────────────────────────────────────────────────────
  //  BUILD — Layout fixe 3 zones, zéro scroll
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final articleState = ref.watch(articleProvider);
    final article      = articleState.article;

    ref.listen<ArticleState>(articleProvider, (prev, next) {
      if (next.article != null && prev?.article == null) {
        // Nouvel article chargé → reset la zone encodage
        _resetForNextTag();
        _articleEntranceCtrl.forward(from: 0);
      }
    });
    ref.listen<RfidState>(rfidProvider, (_, next) {
      if (next.error != null && mounted) _showError(next.error!);
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {},
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              // ── Champ DataWedge invisible — scan article ──
              if (_articleScanMode)
                Positioned(
                  top: -100,
                  child: SizedBox(
                    width: 1, height: 1,
                    child: TextField(
                      controller: _articleScanController,
                      focusNode:  _articleFocusNode,
                      autofocus:  true,
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

              // ── Contenu principal ──
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // ① HEADER
                    _buildHeader(),

                    // ② BANNER scan article en attente
                    // Masqué après un succès : DataWedge écoute en silence
                    if (_articleScanMode && !_successShown)
                      _buildScanArticleBanner(),

                    // ③ CARTE ARTICLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: articleState.isLoading
                          ? _buildArticleLoading()
                          : article != null
                          ? _buildArticleCard(article)
                          : articleState.error != null
                          ? _buildErrorBanner(articleState.error!)
                          : const SizedBox.shrink(),
                    ),

                    // ④ ZONE ENCODAGE
                    // Reste visible pendant le scan post-succès (_successShown + _articleScanMode)
                    if (article != null && (!_articleScanMode || _successShown))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        child: _buildEncodingZone(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              // Bouton retour
              GestureDetector(
                onTap: () => Navigator.pop(context, {
                  'encodedCount': _encodedCount,
                  'sseEntries':   _sseEntries,
                }),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),

              // Titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Encodage étiquette',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text(
                      _encodedCount > 0
                          ? 'Touchez le compteur pour voir la liste'
                          : 'Écriture EPC · Puce vierge',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withOpacity(.75)),
                    ),
                  ],
                ),
              ),

              // COMPTEUR cliquable avec animation
              GestureDetector(
                onTap: _encodedCount > 0 ? _openSseList : null,
                child: AnimatedBuilder(
                  animation: _counterCtrl,
                  builder: (_, __) {
                    final scale = 1.0 + .18 * math.sin(_counterCtrl.value * math.pi);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _encodedCount > 0
                              ? Colors.white.withOpacity(.25)
                              : Colors.white.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white
                                .withOpacity(_encodedCount > 0 ? .5 : .2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              '$_encodedCount encodé${_encodedCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (_encodedCount > 0) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 13),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  BANNER — scan article en attente
  // ──────────────────────────────────────────────────────────────
  Widget _buildScanArticleBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Icône scan animée
          AnimatedBuilder(
            animation: _scanRingCtrl,
            builder: (_, __) {
              final scale = 1.0 + .12 * math.sin(_scanRingCtrl.value * math.pi * 2);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.warning, size: 18),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scannez le code article',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7B5800))),
                const SizedBox(height: 2),
                Text('Pointez le pistolet vers le code-barres du produit',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning.withOpacity(.85),
                        height: 1.3)),
              ],
            ),
          ),
          // Bouton annuler
          GestureDetector(
            onTap: () {
              _focusKeepAliveTimer?.cancel();
              setState(() { _articleScanMode = false; });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Annuler',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  CARTE ARTICLE — compacte pour laisser de la place en bas
  // ──────────────────────────────────────────────────────────────
  Widget _buildArticleCard(ArticleModel article) {
    final photoUrl =
        'https://digitalapi.monchaussea.com/store-api/api/image/produit/${article.codeMod}.jpg';

    return FadeTransition(
      opacity: _articleEntranceCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _articleEntranceCtrl, curve: Curves.easeOutCubic)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.success.withOpacity(.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withOpacity(.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15)),
                child: Image.network(
                  photoUrl,
                  width: 80,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 88,
                    color: AppColors.bg,
                    child: const Icon(Icons.image_outlined,
                        size: 28, color: AppColors.textMuted),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 80,
                      height: 88,
                      color: AppColors.bg,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    );
                  },
                ),
              ),

              // Infos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + marque
                      Text(article.libArticle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(article.marque,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),

                      // Chips taille + coloris
                      Wrap(spacing: 5, runSpacing: 4, children: [
                        if (article.libTaille.isNotEmpty)
                          _Chip(article.libTaille, AppColors.primary),
                        if (article.libColoris.isNotEmpty)
                          _Chip(article.libColoris,
                              const Color(0xFF7C3AED)),
                      ]),
                    ],
                  ),
                ),
              ),

              // Prix + badge prêt
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(article.prixFormate,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Prêt',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleLoading() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16)),
      child: const Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          SizedBox(width: 10),
          Text('Chargement article...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  ZONE ENCODAGE — centrée dans l'Expanded, zéro scroll
  // ──────────────────────────────────────────────────────────────
  Widget _buildEncodingZone() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // État initial : attente scan
        if (!_successShown &&
            _factoryEpc == null &&
            !_isProcessing &&
            _error == null)
          _buildScanInstruction(),

        // En cours
        if (_isProcessing) _buildProcessingCard(),

        // Erreur + bouton réessayer
        if (_error != null)
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final dx = math.sin(_shakeCtrl.value * math.pi * 6) *
                  6 *
                  (1 - _shakeCtrl.value);
              return Transform.translate(
                  offset: Offset(dx, 0), child: child);
            },
            child: _buildErrorCard(_error!),
          ),

        // Résultat EPC (usine → nouveau)
        if (_factoryEpc != null && _newEpc != null) ...[
          _buildEpcTransformCard(),
          const SizedBox(height: 10),
        ],

        // Succès + actions (MODIF 2 : bouton "Scanner autre article" supprimé)
        if (_successShown) _buildSuccessCard(),
      ],
    );
  }

  // ── Instruction initiale ──
  Widget _buildScanInstruction() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: AppColors.primary.withOpacity(.2), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(2, (i) {
                  final delay = i * .5;
                  return AnimatedBuilder(
                    animation: _scanRingCtrl,
                    builder: (_, __) {
                      final v = (_scanRingCtrl.value - delay) % 1.0;
                      return Opacity(
                        opacity: (1 - v).clamp(0.0, 1.0),
                        child: Container(
                          width: 22 + 26 * v,
                          height: 22 + 26 * v,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary
                                  .withOpacity((1 - v) * .45),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.nfc_rounded,
                      color: AppColors.primary, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approchez la puce',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 3),
                Text(
                  'Placez une puce vierge sur le lecteur\npuis appuyez sur le bouton latéral',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(.8),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── En cours ──
  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: AppColors.warning.withOpacity(.25), width: 1.5),
      ),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warning.withOpacity(.3))),
            SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.warning)),
            const Icon(Icons.edit_rounded, color: AppColors.warning, size: 14),
          ]),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Encodage en cours...',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning)),
                SizedBox(height: 3),
                Text('Ne bougez pas la puce du lecteur',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EPC usine → Nouvel EPC (affichage horizontal compact) ──
  Widget _buildEpcTransformCard() {
    return FadeTransition(
      opacity: _encodingEntranceCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _encodingEntranceCtrl, curve: Curves.easeOutCubic)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(.15)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              // Label
              Row(
                children: const [
                  Icon(Icons.memory_rounded,
                      color: AppColors.primary, size: 14),
                  SizedBox(width: 6),
                  Text('Transformation EPC',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: .3)),
                ],
              ),
              const SizedBox(height: 10),

              // Ancien EPC
              _EpcLine(
                label: 'EPC usine',
                value: _factoryEpc!,
                color: AppColors.textSecondary,
                icon: Icons.history_rounded,
              ),

              // Flèche
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: AppColors.primary, size: 13),
                    ),
                  ],
                ),
              ),

              // Nouvel EPC
              _EpcLine(
                label: 'Nouvel EPC',
                value: _newEpc!,
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
                highlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Succès — MODIF 2 : bouton "Scanner un autre article" supprimé ──
  // ── L'utilisateur appuie directement sur le bouton Zebra            ──
  Widget _buildSuccessCard() {
    return FadeTransition(
      opacity: _successCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _successCtrl, curve: Curves.easeOutCubic)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.success.withOpacity(.3), width: 1.5),
          ),
          child: Column(
            children: [
              // Icône + texte succès
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.success.withOpacity(.3),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Encodage réussi !',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success)),
                        Text(
                          'Appuyez sur le bouton Zebra pour scanner\nun nouvel article.',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                              AppColors.textSecondary.withOpacity(.8),
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lien liste
              GestureDetector(
                onTap: _openSseList,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withOpacity(.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt_rounded,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$_encodedCount puce${_encodedCount > 1 ? 's' : ''} encodée${_encodedCount > 1 ? 's' : ''} — voir la liste',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.success, size: 14),
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

  // ── Erreur + bouton réessayer ──
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: AppColors.error.withOpacity(.25), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(error,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(.4)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Réessayer',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: _resetForNextTag,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: AppColors.error.withOpacity(.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(error,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.error, height: 1.4))),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  COMPOSANTS
// ──────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _EpcLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool highlight;

  const _EpcLine({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withOpacity(highlight ? .3 : .1),
            width: highlight ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: color.withOpacity(.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3)),
                const SizedBox(height: 2),
                SelectableText(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: .8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}