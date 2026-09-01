import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/qc_provider.dart';
import '../../rfid/providers/rfid_provider.dart';

class QcInventoryPage extends ConsumerStatefulWidget {
  final QcControlMode mode;
  const QcInventoryPage({super.key, required this.mode});

  @override
  ConsumerState<QcInventoryPage> createState() => _QcInventoryPageState();
}

class _QcInventoryPageState extends ConsumerState<QcInventoryPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseCtrl;

  static const _indigo = Color(0xFF3949AB);
  static const _indigoDark = Color(0xFF1A237E);
  static const _green = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFFFEBEB);
  static const _bg = Color(0xFFF0F2FF);
  static const _surface = Colors.white;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )
      ..repeat(reverse: true);

  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final qcState = ref.watch(qcProvider);
    final rfidState = ref.watch(rfidProvider);
    final colisResult = qcState.currentColisResult;
    final isRunning = qcState.isInventoryRunning;
    final isStarted = qcState.inventoryStarted;
    final isFull = widget.mode == QcControlMode.full;
    final totalColis = qcState.colisResults.length;
    final currentIndex = qcState.currentColisIndex;
    final isConnected = rfidState.connectedReader != null;

    return PopScope(
      canPop: false, // on gère nous-mêmes le retour
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isRunning) {
          await ref.read(qcProvider.notifier).stopInventory();
        }
        ref.read(qcProvider.notifier).resetInventory();
        if (mounted) Navigator.pop(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _buildHeader(isRunning, isFull, currentIndex,
                  totalColis, colisResult, isConnected),
              Expanded(
                child: colisResult == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBody(
                    colisResult,
                    isRunning,
                    isStarted,
                    isFull,
                    currentIndex,
                    totalColis,
                    qcState,
                    isConnected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(bool isRunning, bool isFull, int currentIndex,
      int totalColis, QcColisResult? colisResult, bool isConnected) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigoDark, _indigo],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // ── Ligne 1 : retour + titre + statut inventaire ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (isRunning) {
                        await ref.read(qcProvider.notifier).stopInventory();
                      }
                      ref.read(qcProvider.notifier).resetInventory();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFull ? 'Full Control' : 'Partial Control',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge statut inventaire
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) =>
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isRunning
                                ? Colors.green.withValues(alpha: .2 +
                                .1 * _pulseCtrl.value)
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
                                isRunning ? 'Reading...' : 'Waiting',
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

              // ── Ligne 2 : statut lecteur RFID ──
              _buildReaderStatusBanner(isConnected),
              // Info colis courant
              if (colisResult != null) ...[
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
                      Text(
                        colisResult.colis.codeColis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${colisResult.totalLu} / ${colisResult
                            .totalAttendu} items',
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

  // ── Bandeau lecteur ───────────────────────────────────────

  Widget _buildReaderStatusBanner(bool isConnected) {
    final rfidState = ref.watch(rfidProvider);
    final reader = rfidState.connectedReader;

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
          Icon(
            Icons.nfc_rounded,
            color: isConnected ? Colors.greenAccent : Colors.redAccent,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? 'Reader: ${reader!.name}'
                  : 'No reader connected',
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

  // ── Corps ─────────────────────────────────────────────────

  Widget _buildBody(QcColisResult colisResult,
      bool isRunning,
      bool isStarted,
      bool isFull,
      int currentIndex,
      int totalColis,
      QcState qcState,
      bool isConnected,) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultTable(colisResult, isRunning, isStarted),
          const SizedBox(height: 16),

          // ── Boutons selon état ──
          if (!isStarted)
          // Pas encore lancé → bouton Commencer
            _buildStartButton(isConnected)
          else
            if (isRunning)
            // En cours → bouton Arrêter
              _buildStopButton()
            else
              if (isFull && currentIndex < totalColis - 1)
              // Full control, colis suivant
                _buildNextColisButton(qcState)
              else
              // Terminé → bouton Terminer
                _buildFinishButton(qcState),
        ],
      ),
    );
  }

  // ── Tableau résultat ──────────────────────────────────────
  Widget _buildResultTable(QcColisResult colisResult, bool isRunning,
      bool isStarted) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
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
            decoration: const BoxDecoration(
              color: _indigo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2,
                    child: Text('Size',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800, color: Colors.white))),
                Expanded(flex: 2,
                    child: Text('Expected',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800, color: Colors.white))),
                Expanded(flex: 2,
                    child: Text('Read',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800, color: Colors.white))),
                Expanded(flex: 2,
                    child: Text('Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800, color: Colors.white))),
              ],
            ),
          ),

          // Lignes
          ...colisResult.tailleResults
              .asMap()
              .entries
              .map((entry) {
            final i = entry.key;
            final t = entry.value;
            final isLast = i == colisResult.tailleResults.length - 1;
            final isEven = i % 2 == 0;
            return _buildTableRow(t, isLast, isEven, isRunning, isStarted);
          }),

          // Ligne total
          _buildTotalRow(colisResult, isStarted),
        ],
      ),
    );
  }

  Widget _buildTableRow(QcTailleResult t, bool isLast, bool isEven,
      bool isRunning, bool isStarted) {
    Widget statusWidget;

    if (!isStarted) {
      statusWidget = Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: .1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.remove, color: Colors.grey, size: 12),
      );
    } else if (isRunning && t.qteLue == 0) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) =>
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .1 + .05 * _pulseCtrl.value),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty_rounded,
                  color: Colors.orange, size: 12),
            ),
      );
    } else if (isRunning && t.qteLue > 0 && !t.isOk) {
      statusWidget = AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) =>
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: .1 + .05 * _pulseCtrl.value),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withValues(alpha: .5)),
              ),
              child: const Icon(Icons.hourglass_bottom_rounded,
                  color: Colors.orange, size: 12),
            ),
      );
    } else if (t.isOk && t.qteLue > 0) {
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
        color: isEven ? Colors.white : const Color(0xFFF8F9FF),
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.withValues(alpha: .1)),
        ),
      ),
      child: Row(
        children: [
          // Pointure
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _indigo.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t.pointure,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _indigo),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Attendu
          Expanded(
            flex: 2,
            child: Text('${t.qteAttendue}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444441))),
          ),
          // Lu
          Expanded(
            flex: 2,
            child: Text(
              isStarted ? '${t.qteLue}' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: !isStarted
                    ? Colors.grey
                    : t.qteLue == 0
                    ? Colors.grey
                    : t.isOk ? _green : Colors.orange,
              ),
            ),
          ),
          // Statut
          Expanded(flex: 2, child: Center(child: statusWidget)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(QcColisResult colisResult, bool isStarted) {
    if (!isStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
        ),
        child: const Row(
          children: [
            Expanded(flex: 2,
                child: Text('TOTAL',
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w900, color: Colors.grey))),
            Expanded(flex: 6,
                child: Text('— Waiting to start —',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11,
                        color: Colors.grey, fontStyle: FontStyle.italic))),
          ],
        ),
      );
    }

    final allOk = colisResult.isAllOk && colisResult.totalLu > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: allOk ? _greenLight : _redLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2,
              child: Text('TOTAL',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(flex: 2,
              child: Text('${colisResult.totalAttendu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(flex: 2,
              child: Text('${colisResult.totalLu}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: allOk ? _green : _red))),
          Expanded(flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: allOk ? _green : _red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    allOk ? 'Compliant' : 'Discrepancy',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Bouton Commencer ──────────────────────────────────────

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
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please connect an RFID reader before starting.',
                    style: TextStyle(fontSize: 11,
                        color: _red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isConnected
                ? () => ref.read(qcProvider.notifier).startInventory()
                : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Start control',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
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

  // ── Bouton Stop ───────────────────────────────────────────

  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => ref.read(qcProvider.notifier).stopInventory(),
        icon: const Icon(Icons.stop_rounded, size: 18),
        label: const Text('Stop reading',
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

  // ── Bouton Colis suivant ──────────────────────────────────

  Widget _buildNextColisButton(QcState qcState) {
    final nextColis = qcState.colisResults[qcState.currentColisIndex + 1];
    return Column(
      children: [
        _buildColisSummary(qcState.currentColisResult!),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => ref.read(qcProvider.notifier).nextColis(),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(
              'Next parcel: ${nextColis.colis.codeColis}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton Terminer ───────────────────────────────────────

  Widget _buildFinishButton(QcState qcState) {
    return Column(
      children: [
        _buildColisSummary(qcState.currentColisResult!),
        const SizedBox(height: 10),
        Row(
          children: [
            // Bouton Refaire
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(qcProvider.notifier).resetInventory();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Redo',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Bouton Terminer
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(qcProvider.notifier).resetInventory();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Finish',
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

  // ── Résumé colis ──────────────────────────────────────────

  Widget _buildColisSummary(QcColisResult colisResult) {
    final ok = colisResult.tailleResults
        .where((t) => t.isOk && t.qteLue > 0)
        .length;
    final ecart = colisResult.totalAttendu - colisResult.totalLu;
    final isOk = ecart == 0 && colisResult.totalLu > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, color: _green, size: 13),
        const SizedBox(width: 4),
        Text('$ok compliant${ok > 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _green)),

        const SizedBox(width: 10),
        Container(width: 1, height: 12, color: Colors.grey.withValues(alpha: .3)),
        const SizedBox(width: 10),

        Icon(Icons.nfc_rounded, color: _indigo, size: 13),
        const SizedBox(width: 4),
        Text('${colisResult.totalLu}/${colisResult.totalAttendu}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _indigo)),

        const SizedBox(width: 10),
        Container(width: 1, height: 12, color: Colors.grey.withValues(alpha: .3)),
        const SizedBox(width: 10),

        Icon(isOk ? Icons.check_rounded : Icons.warning_amber_rounded,
            color: isOk ? _green : _red, size: 13),
        const SizedBox(width: 4),
        Text(isOk ? 'Compliant' : 'Discrepancy : $ecart',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: isOk ? _green : _red)),
      ],
    );
  }
}

// ── Summary Chip ──────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 8, color: color.withValues(alpha: .7),
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}