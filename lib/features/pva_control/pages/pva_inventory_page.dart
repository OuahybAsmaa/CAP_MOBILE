import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pva_model.dart';
import '../providers/pva_provider.dart';
import '../../rfid/providers/rfid_provider.dart';
import '../../../core/services/article_service.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';

class PvaInventoryPage extends ConsumerStatefulWidget {
  const PvaInventoryPage({super.key});

  @override
  ConsumerState<PvaInventoryPage> createState() => _PvaInventoryPageState();
}

class _PvaInventoryPageState extends ConsumerState<PvaInventoryPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseCtrl;

  static const _purple      = Color(0xFF4A148C);
  static const _purpleMid   = Color(0xFF7B1FA2);
  static const _green       = Color(0xFF2E7D32);
  static const _greenLight  = Color(0xFFE8F5E9);
  static const _red         = Color(0xFFD32F2F);
  static const _redLight    = Color(0xFFFFEBEB);
  static const _bg          = Color(0xFFF5F0FF);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s          = ref.watch(pvaProvider);
    final rfid       = ref.watch(rfidProvider);
    final isRunning  = s.isInventoryRunning;
    final isStarted  = s.inventoryStarted;
    final isConnected = rfid.connectedReader != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isRunning) {
          await ref.read(pvaProvider.notifier).stopInventory();
        }
        ref.read(pvaProvider.notifier).resetInventory();
        if (mounted) Navigator.pop(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _buildHeader(s, isRunning, isConnected),
              Expanded(
                child: _buildBody(s, isRunning, isStarted, isConnected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader(PvaState s, bool isRunning, bool isConnected) {
    final r = s.reception;
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
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (isRunning) {
                        await ref.read(pvaProvider.notifier).stopInventory();
                      }
                      ref.read(pvaProvider.notifier).resetInventory();
                      if (mounted) Navigator.pop(context);
                    },
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
                  Expanded(
                    child: Text(
                      context.f.pvaInventoryTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Badge Running / Waiting
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? Colors.green
                            .withValues(alpha: .2 + .1 * _pulseCtrl.value)
                            : Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRunning
                              ? Colors.greenAccent.withValues(alpha: .6)
                              : Colors.white.withValues(alpha: .3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: isRunning
                                  ? Colors.greenAccent
                                  : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isRunning ? context.f.pvaInventoryRunning : context.f.pvaInventoryWaiting,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              _buildReaderBanner(isConnected),

              if (r != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.codeSupport,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      Text(
                        '${s.totalLu} / ${s.totalAttendu} ${context.f.pvaArticles}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: .8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderBanner(bool isConnected) {
    final reader = ref.watch(rfidProvider).connectedReader;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: .15)
            : Colors.red.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: .4)
              : Colors.redAccent.withValues(alpha: .4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.nfc_rounded,
              color: isConnected ? Colors.greenAccent : Colors.redAccent,
              size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? '${context.f.pvaInventoryReaderPrefix}${reader!.name}'
                  : context.f.pvaInventoryNoReader,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isConnected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isConnected ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ── Corps ──────────────────────────────────────────────────

  Widget _buildBody(PvaState s, bool isRunning, bool isStarted,
      bool isConnected) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultTable(s, isRunning, isStarted),
          const SizedBox(height: 16),
          if (!isStarted)
            _buildStartButton(isConnected)
          else if (isRunning)
            _buildStopButton()
          else
            _buildFinishButtons(s),
        ],
      ),
    );
  }

  // ── Tableau ────────────────────────────────────────────────

  Widget _buildResultTable(PvaState s, bool isRunning, bool isStarted) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _purpleMid,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2,
                    child: Text(context.f.pvaTableSize,
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(flex: 2,
                    child: Text(context.f.pvaTableExpected,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(flex: 2,
                    child: Text(context.f.pvaTableRead,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(flex: 2,
                    child: Text(context.f.pvaTableStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
              ],
            ),
          ),

          ...s.ligneResults.asMap().entries.map((entry) {
            final i    = entry.key;
            final l    = entry.value;
            final last = i == s.ligneResults.length - 1;
            return _buildRow(l, last, i % 2 == 0, isRunning, isStarted);
          }),

          _buildTotalRow(s, isStarted),
        ],
      ),
    );
  }

  Widget _buildRow(PvaLigneResult l, bool isLast, bool isEven,
      bool isRunning, bool isStarted) {
    Widget statusWidget;

    if (!isStarted) {
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: .1),
            shape: BoxShape.circle),
        child: const Icon(Icons.remove, color: Colors.grey, size: 12),
      );
    } else if (isRunning && l.qteLue == 0) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: Colors.orange
                .withValues(alpha: .1 + .05 * _pulseCtrl.value),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_empty_rounded,
              color: Colors.orange, size: 12),
        ),
      );
    } else if (isRunning && l.qteLue > 0 && !l.isOk) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: Colors.orange
                .withValues(alpha: .1 + .05 * _pulseCtrl.value),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.orange.withValues(alpha: .5)),
          ),
          child: const Icon(Icons.hourglass_bottom_rounded,
              color: Colors.orange, size: 12),
        ),
      );
    } else if (l.isOk && l.qteLue > 0) {
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: _greenLight,
          shape: BoxShape.circle,
          border: Border.all(color: _green.withValues(alpha: .4)),
        ),
        child: const Icon(Icons.check_rounded, color: _green, size: 12),
      );
    } else {
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: _redLight,
          shape: BoxShape.circle,
          border: Border.all(color: _red.withValues(alpha: .4)),
        ),
        child: const Icon(Icons.close_rounded, color: _red, size: 12),
      );
    }

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
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: Image.network(
                        ArticleService().getPhotoUrl(l.ligne.codeMod),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _purpleMid.withValues(alpha: .08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _purpleMid,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _purpleMid.withValues(alpha: .08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: _purpleMid.withValues(alpha: .4),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _purpleMid,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          l.ligne.libTaille,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${l.ligne.qte}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444441))),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isStarted ? '${l.qteLue}' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: !isStarted
                    ? Colors.grey
                    : l.qteLue == 0
                    ? Colors.grey
                    : l.isOk
                    ? _green
                    : Colors.orange,
              ),
            ),
          ),
          Expanded(flex: 2, child: Center(child: statusWidget)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(PvaState s, bool isStarted) {
    if (!isStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
        ),
        child: Row(
          children: [
            Expanded(flex: 2,
                child: Text(context.f.pvaTableTotal,
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey))),
            Expanded(flex: 6,
                child: Text(context.f.pvaTableWaitingScan,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic))),
          ],
        ),
      );
    }

    final allOk = s.isAllOk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: allOk ? _greenLight : _redLight,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2,
              child: Text(context.f.pvaTableTotal,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(flex: 2,
              child: Text('${s.totalAttendu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(flex: 2,
              child: Text('${s.totalLu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: allOk ? _green : _red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  allOk ? context.f.pvaTableConform : context.f.pvaTableGap,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons ────────────────────────────────────────────────

  Widget _buildStartButton(bool isConnected) {
    return Column(
      children: [
        if (!isConnected)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _redLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withValues(alpha: .3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD32F2F), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.f.pvaNoReaderConnectedWarning,
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isConnected
                ? () => ref.read(pvaProvider.notifier).startInventory()
                : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(context.f.pvaBtnStart,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purpleMid,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => ref.read(pvaProvider.notifier).stopInventory(),
        icon: const Icon(Icons.stop_rounded, size: 18),
        label: Text(context.f.pvaBtnStop,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildFinishButtons(PvaState s) {
    final ecart = s.totalAttendu - s.totalLu;
    final isOk  = s.isAllOk;
    final ok    = s.ligneResults.where((l) => l.isOk && l.qteLue > 0).length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 13),
            const SizedBox(width: 4),
            Text('$ok ${context.f.pvaConformeLabel}${ok > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green)),
            const SizedBox(width: 10),
            Container(width: 1, height: 12,
                color: Colors.grey.withValues(alpha: .3)),
            const SizedBox(width: 10),
            Icon(Icons.nfc_rounded, color: _purpleMid, size: 13),
            const SizedBox(width: 4),
            Text('${s.totalLu}/${s.totalAttendu}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _purpleMid)),
            const SizedBox(width: 10),
            Container(width: 1, height: 12,
                color: Colors.grey.withValues(alpha: .3)),
            const SizedBox(width: 10),
            Icon(
              isOk ? Icons.check_rounded : Icons.warning_amber_rounded,
              color: isOk ? _green : _red,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              isOk ? context.f.pvaTableConform : '${context.f.pvaGapPrefix}$ecart',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOk ? _green : _red),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(pvaProvider.notifier).resetInventory(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.f.pvaBtnRedo,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(pvaProvider.notifier).resetInventory();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(context.f.pvaBtnFinish,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}