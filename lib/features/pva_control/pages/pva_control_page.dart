import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/article_service.dart';
import '../../../core/services/datawedge_service.dart';
import '../models/pva_model.dart';
import '../providers/pva_provider.dart';
import '../../../features/rfid/providers/rfid_provider.dart';
import 'pva_inventory_page.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';

class PvaControlPage extends ConsumerStatefulWidget {
  const PvaControlPage({super.key});

  @override
  ConsumerState<PvaControlPage> createState() => _PvaControlPageState();
}

class _PvaControlPageState extends ConsumerState<PvaControlPage>
    with SingleTickerProviderStateMixin {

  StreamSubscription<String>? _scanSubscription;
  late final AnimationController _pulseCtrl;

  static const _purple    = Color(0xFF4A148C);
  static const _purpleMid = Color(0xFF7B1FA2);
  static const _purpleLight = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pvaProvider.notifier).reset();
      _connectRfidIfNeeded();
      _initDataWedge();
    });
  }

  void _connectRfidIfNeeded() {
    final rfid = ref.read(rfidProvider);
    if (rfid.connectedReader != null) return;

    ref.read(rfidProvider.notifier).loadAvailableReaders().then((_) {
      final updated = ref.read(rfidProvider);
      if (updated.availableReaders.isNotEmpty &&
          updated.connectedReader == null) {
        ref
            .read(rfidProvider.notifier)
            .connectToReader(updated.availableReaders.first);
      }
    });
  }

  void _initDataWedge() {
    _scanSubscription = ref
        .read(dataWedgeServiceProvider)
        .onScan
        .listen((data) {
      if (!mounted) return;
      final s    = ref.read(pvaProvider);
      final rfid = ref.read(rfidProvider);

      if (!s.isLoadingRecep && rfid.connectedReader != null && !rfid.isLoading) {
        ref.read(pvaProvider.notifier).reset();
        ref.read(pvaProvider.notifier).onCodeScanned(data);
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pvaProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0FF),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(s)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple, _purpleMid],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: .12 + .06 * _pulseCtrl.value),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .3)),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.f.pvaInventoryTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .4,
                    ),
                  ),
                  Text(
                    context.f.pvaControlSubtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: .7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildReaderBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderBadge() {
    final rfidState     = ref.watch(rfidProvider);
    final uniqueReaders = rfidState.availableReaders.toSet().toList();
    final connected     = rfidState.connectedReader;

    return GestureDetector(
      onTap: rfidState.isLoading
          ? null
          : () => _showReaderPicker(connected, rfidState, uniqueReaders),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: connected != null
              ? Colors.green.withValues(alpha: .2)
              : Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: connected != null
                ? Colors.greenAccent.withValues(alpha: .6)
                : Colors.white.withValues(alpha: .3),
          ),
        ),
        child: rfidState.isLoading && connected == null
            ? const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Colors.white),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: connected != null
                    ? Colors.greenAccent
                    : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              connected != null ? context.f.pvaReaderConnected : context.f.pvaReaderDisconnected,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: connected != null
                    ? Colors.greenAccent
                    : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderPicker(connected, RfidState rfidState, List uniqueReaders) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.f.pvaReaderDialogTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(rfidProvider.notifier).loadAvailableReaders();
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: _purpleMid, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (uniqueReaders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(context.f.pvaNoReaderAvailable,
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              )
            else
              ...uniqueReaders.map((r) {
                final isSelected = connected?.name == r.name;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (isSelected) {
                      ref.read(rfidProvider.notifier).disconnectReader();
                    } else {
                      if (connected != null) {
                        ref.read(rfidProvider.notifier).disconnectReader();
                      }
                      ref.read(rfidProvider.notifier).connectToReader(r);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A148C).withValues(alpha: .06)
                          : const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _purpleMid
                            : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.nfc_rounded,
                            color: isSelected ? _purpleMid : Colors.grey,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? _purpleMid
                                    : const Color(0xFF1A1A2E),
                              )),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: _purpleMid, size: 16),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Corps ──────────────────────────────────────────────────

  Widget _buildBody(PvaState s) {
    if (s.isLoadingRecep) return _buildLoading(s);
    if (s.error != null)  return _buildError(s.error!);
    if (s.reception != null) return _buildReceptionCard(s);
    return _buildScanWaiting();
  }

  // ── Attente scan ───────────────────────────────────────────

  Widget _buildScanWaiting() {
    final isConnected = ref.watch(rfidProvider).connectedReader != null;
    final isLoading   = ref.watch(rfidProvider).isLoading;
    final isReady     = isConnected && !isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: isReady ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) => Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: _purpleMid
                          .withValues(alpha: .08 + .04 * _pulseCtrl.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _purpleMid
                            .withValues(alpha: .2 + .1 * _pulseCtrl.value),
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded,
                        size: 40, color: _purpleMid),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.f.pvaScanTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isReady ? context.f.pvaScanSubtitleReady : context.f.pvaScanSubtitleNotReady,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Warning si pas de lecteur
                if (!isReady)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFD32F2F).withValues(alpha: .3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFD32F2F), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.f.pvaNoReaderWarning,
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _purpleMid.withValues(alpha: .3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: _purpleMid, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.f.pvaScanInfo,
                            style: TextStyle(
                              fontSize: 11,
                              color: _purple,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chargement ─────────────────────────────────────────────

  Widget _buildLoading(PvaState s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _purpleMid,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.f.pvaLoadingTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${context.f.pvaLoadingCodePrefix}${s.scannedCode}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Erreur ─────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE57373)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 20),
            Text(
              context.f.pvaErrorTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD32F2F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => ref.read(pvaProvider.notifier).reset(),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: Text(context.f.pvaBtnScanAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purpleMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carte réception ────────────────────────────────────────

  Widget _buildReceptionCard(PvaState s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceptionInfoCard(s),
          const SizedBox(height: 14),
          _buildLignesPreview(s),
        ],
      ),
    );
  }

  Widget _buildReceptionInfoCard(PvaState s) {
    final r = s.reception!;
    final connected = ref.watch(rfidProvider).connectedReader != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code support + badge PVA
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: _purpleMid, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.codeSupport,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: .3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _purpleMid.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAV',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _purpleMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          // Nombre d'articles + bouton lancer le contrôle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.totalAttendu} ${r.totalAttendu > 1 ? context.f.pvaArticles : context.f.pvaArticle}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _purple,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: connected
                    ? () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                    const PvaInventoryPage(),
                    transitionsBuilder:
                        (_, anim, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration:
                    const Duration(milliseconds: 300),
                  ),
                )
                    : null,
                icon: const Icon(Icons.nfc_rounded, size: 16),
                label: Text(context.f.pvaBtnLaunch,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleMid,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          if (!connected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD32F2F).withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD32F2F), size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.f.pvaNoReaderCannotLaunch,
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLignesPreview(PvaState s) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _purpleMid,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                SizedBox(width: 48),
                Expanded(
                  flex: 5,
                  child: Text(context.f.pvaTableArticle,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(context.f.pvaTableSize,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(context.f.pvaTableQty,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),

          // Lignes
          ...s.ligneResults.asMap().entries.map((entry) {
            final i    = entry.key;
            final lr   = entry.value;
            final l    = lr.ligne;
            final isEven = i % 2 == 0;
            final isLast = i == s.ligneResults.length - 1;
            final imageUrl = ArticleService().getPhotoUrl(l.codeMod);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0xFFFAF5FF),
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.withValues(alpha: .1)),
                ),
              ),
              child: Row(
                children: [
                  // Image article
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: l.codeMod.isEmpty
                        ? Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _purpleMid.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _purpleMid,
                          ),
                        ),
                      ),
                    )
                        : Image.network(
                      imageUrl,
                      width: 46, height: 46,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: _purpleMid.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _purpleMid,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: _purpleMid.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: _purpleMid.withValues(alpha: .4),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // EAN
                  Expanded(
                    flex: 5,
                    child: Text(
                      l.ean,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444441),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Taille
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _purpleMid.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.libTaille,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _purpleMid,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Quantité
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${l.qte}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}