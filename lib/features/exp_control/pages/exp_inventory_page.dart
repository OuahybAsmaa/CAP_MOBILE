import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exp_model.dart';
import '../providers/exp_provider.dart';
import '../../rfid/providers/rfid_provider.dart';

// ─────────────────────────────────────────────────────────────
//  PAGE INVENTAIRE RFID — Contrôle EXP
// ─────────────────────────────────────────────────────────────

class ExpInventoryPage extends ConsumerStatefulWidget {
  const ExpInventoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ExpInventoryPage> createState() =>
      _ExpInventoryPageState();
}

class _ExpInventoryPageState extends ConsumerState<ExpInventoryPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseCtrl;

  static const _indigo     = Color(0xFF1A237E);
  static const _indigoMid  = Color(0xFF3949AB);
  static const _green      = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _red        = Color(0xFFD32F2F);
  static const _redLight   = Color(0xFFFFEBEB);
  static const _bg         = Color(0xFFF0F2FF);

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

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s          = ref.watch(expProvider);
    final rfid       = ref.watch(rfidProvider);
    final isRunning  = s.isInventoryRunning;
    final isStarted  = s.inventoryStarted;
    final isConnected = rfid.connectedReader != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isRunning) {
          await ref.read(expProvider.notifier).stopInventory();
        }
        ref.read(expProvider.notifier).resetInventory();
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

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(ExpState s, bool isRunning, bool isConnected) {
    final r = s.reception;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigo, _indigoMid],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // ── Ligne 1 : retour + titre + badge scan ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (isRunning) {
                        await ref.read(expProvider.notifier).stopInventory();
                      }
                      ref.read(expProvider.notifier).resetInventory();
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contrôle EXP',
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
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? Colors.green
                            .withOpacity(.2 + .1 * _pulseCtrl.value)
                            : Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRunning
                              ? Colors.greenAccent.withOpacity(.6)
                              : Colors.white.withOpacity(.3),
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
                            isRunning ? 'Lecture...' : 'En attente',
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

              // ── Ligne 2 : état du lecteur RFID ──
              _buildReaderBanner(isConnected),

              // ── Ligne 3 : résumé de la réception ──
              if (r != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.codeRecep,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      Text(
                        '${s.totalLu} / ${s.totalAttendu} articles',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(.8),
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
            ? Colors.green.withOpacity(.15)
            : Colors.red.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withOpacity(.4)
              : Colors.redAccent.withOpacity(.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nfc_rounded,
            color: isConnected ? Colors.greenAccent : Colors.redAccent,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? 'Lecteur : ${reader!.name}'
                  : 'Aucun lecteur connecté',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                isConnected ? Colors.greenAccent : Colors.redAccent,
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

  // ── Corps ─────────────────────────────────────────────────

  Widget _buildBody(ExpState s, bool isRunning, bool isStarted,
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

  // ── Tableau résultats ─────────────────────────────────────

  Widget _buildResultTable(ExpState s, bool isRunning, bool isStarted) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: _indigoMid,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Taille',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(
                    flex: 2,
                    child: Text('Attendu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(
                    flex: 2,
                    child: Text('Lu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                Expanded(
                    flex: 2,
                    child: Text('Statut',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
              ],
            ),
          ),

          // Lignes
          ...s.ligneResults.asMap().entries.map((entry) {
            final i    = entry.key;
            final l    = entry.value;
            final last = i == s.ligneResults.length - 1;
            return _buildRow(l, last, i % 2 == 0, isRunning, isStarted);
          }),

          // Total
          _buildTotalRow(s, isStarted),
        ],
      ),
    );
  }

  Widget _buildRow(ExpLigneResult l, bool isLast, bool isEven,
      bool isRunning, bool isStarted) {
    Widget statusWidget;

    if (!isStarted) {
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.remove, color: Colors.grey, size: 12),
      );
    } else if (isRunning && l.qteLue == 0) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: Colors.orange
                .withOpacity(.1 + .05 * _pulseCtrl.value),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_empty_rounded,
              color: Colors.orange, size: 12),
        ),
      );
    } else if (isRunning && l.qteLue > 0 && !l.isOk) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: Colors.orange
                .withOpacity(.1 + .05 * _pulseCtrl.value),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.orange.withOpacity(.5)),
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
          border:
          Border.all(color: _green.withOpacity(.4)),
        ),
        child: const Icon(Icons.check_rounded,
            color: _green, size: 12),
      );
    } else {
      // Terminé mais manquant
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: _redLight,
          shape: BoxShape.circle,
          border:
          Border.all(color: _red.withOpacity(.4)),
        ),
        child: const Icon(Icons.close_rounded,
            color: _red, size: 12),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8F9FF),
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.withOpacity(.1)),
        ),
      ),
      child: Row(
        children: [
          // Taille
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _indigoMid.withOpacity(.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l.ligne.libTaille,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _indigoMid,
                ),
              ),
            ),
          ),
          // Attendu
          Expanded(
            flex: 2,
            child: Text(
              '${l.ligne.qte}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444441),
              ),
            ),
          ),
          // Lu
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
          // Statut
          Expanded(
              flex: 2,
              child: Center(child: statusWidget)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ExpState s, bool isStarted) {
    if (!isStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(13)),
        ),
        child: const Row(
          children: [
            Expanded(
                flex: 2,
                child: Text('TOTAL',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey))),
            Expanded(
                flex: 6,
                child: Text('— En attente du lancement —',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic))),
          ],
        ),
      );
    }

    final allOk = s.isAllOk;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: allOk ? _greenLight : _redLight,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('TOTAL',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(
              flex: 2,
              child: Text('${s.totalAttendu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(
              flex: 2,
              child: Text('${s.totalLu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
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
                  allOk ? 'Conforme' : 'Écart',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
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

  // ── Boutons ───────────────────────────────────────────────

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
              border:
              Border.all(color: _red.withOpacity(.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: _red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connectez un lecteur RFID avant de commencer.',
                    style: TextStyle(
                        fontSize: 11,
                        color: _red,
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
                ? () => ref
                .read(expProvider.notifier)
                .startInventory()
                : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Démarrer le contrôle',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigoMid,
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
        onPressed: () =>
            ref.read(expProvider.notifier).stopInventory(),
        icon: const Icon(Icons.stop_rounded, size: 18),
        label: const Text('Arrêter la lecture',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800)),
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

  Widget _buildFinishButtons(ExpState s) {
    final ecart    = s.totalAttendu - s.totalLu;
    final isOk     = s.isAllOk;
    final ok       = s.ligneResults.where((l) => l.isOk && l.qteLue > 0).length;

    return Column(
      children: [
        // ── Résumé ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 13),
            const SizedBox(width: 4),
            Text('$ok conforme${ok > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green)),
            const SizedBox(width: 10),
            Container(
                width: 1,
                height: 12,
                color: Colors.grey.withOpacity(.3)),
            const SizedBox(width: 10),
            Icon(Icons.nfc_rounded, color: _indigoMid, size: 13),
            const SizedBox(width: 4),
            Text('${s.totalLu}/${s.totalAttendu}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _indigoMid)),
            const SizedBox(width: 10),
            Container(
                width: 1,
                height: 12,
                color: Colors.grey.withOpacity(.3)),
            const SizedBox(width: 10),
            Icon(
              isOk
                  ? Icons.check_rounded
                  : Icons.warning_amber_rounded,
              color: isOk ? _green : _red,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              isOk ? 'Conforme' : 'Écart : $ecart',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOk ? _green : _red),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Boutons Refaire / Terminer ──
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(expProvider.notifier).resetInventory(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refaire',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigoMid,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
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
                  ref.read(expProvider.notifier).resetInventory();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_rounded,
                    size: 16),
                label: const Text('Terminer',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
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