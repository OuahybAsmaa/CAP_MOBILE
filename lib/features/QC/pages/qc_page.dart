import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/datawedge_service.dart';
import '../models/qc_model.dart';
import '../providers/qc_provider.dart';
import 'qc_inventory_page.dart';
import '../../../core/services/article_service.dart';
import '../../../features/rfid/providers/rfid_provider.dart';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────
//  PAGE PRINCIPALE
// ─────────────────────────────────────────────────────────────

class QcRfidPage extends ConsumerStatefulWidget {
  const QcRfidPage({super.key});

  @override
  ConsumerState<QcRfidPage> createState() => _QcRfidPageState();
}

class _QcRfidPageState extends ConsumerState<QcRfidPage>
    with SingleTickerProviderStateMixin {

  StreamSubscription<String>? _scanSubscription;
  late final AnimationController _pulseCtrl;
  QcControlMode _selectedMode = QcControlMode.partiel;
  bool _scanColisMode = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _sheetController;
  static const _nativeChannel = MethodChannel('com.example.cap_mobile1/rfid');

  @override
  void initState() {
    super.initState();
    debugPrint('>>> QcRfidPage initState');

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rfidNotifier = ref.read(rfidProvider.notifier);
      final rfidState    = ref.read(rfidProvider);

      if (rfidState.connectedReader == null) {
        rfidNotifier.loadAvailableReaders().then((_) {
          final updated = ref.read(rfidProvider);
          if (updated.availableReaders.isNotEmpty &&
              updated.connectedReader == null) {
            rfidNotifier.connectToReader(updated.availableReaders.first);
          }
        });
      }
    });

    // Reset l'état QC à l'ouverture de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qcProvider.notifier).reset();
    });

    _initDataWedge();
  }

  void _initDataWedge() async {
    await ref.read(dataWedgeServiceProvider).initialize();

    if (!mounted) return;

    // Ecoute des scans venant d'EMDK (scanner interne, decodeur ITF)
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onEmdkScan') {
        final data = call.arguments as String;
        if (!mounted) return;

        // Lire l'état AVANT toute action
        final qcState = ref.read(qcProvider);
        final trimmed = data.trim();

        if (_scanColisMode && qcState.production != null) {
          // Mode scan colis actif → ne jamais faire reset()
          final exists = qcState.production!.colis
              .any((c) => c.codeColis == trimmed);

          if (!exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Colis $trimmed introuvable pour cet article'),
                backgroundColor: const Color(0xFFD32F2F),
                duration: const Duration(seconds: 2),
              ),
            );
            return; // ← IMPORTANT : on sort sans rien faire
          }

          ref.read(qcProvider.notifier).scanColis(trimmed);

          // Ouvre la popup si pas encore ouverte
          if (_sheetController == null) _showScanPopup();

        } else if (!_scanColisMode) {
          // Mode normal → scan gencode article uniquement
          if (!qcState.isLoading) {
            ref.read(qcProvider.notifier).reset();
            ref.read(qcProvider.notifier).onGencodeScanned(trimmed);
          }
        }
        // Si _scanColisMode=true mais production=null : on ignore
      }
    });

    // Demarre le scanner EMDK (bascule depuis DataWedge)
    try {
      await _nativeChannel.invokeMethod('startEmdkScan');
      debugPrint('EMDK scan demarre');
    } catch (e) {
      debugPrint('Erreur demarrage EMDK: $e');
    }
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.replaceAll(' ', '').replaceAll('\n', '');
    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
  @override
  void dispose() {
    debugPrint('>>> QcRfidPage dispose');
    _scanSubscription?.cancel();
    _nativeChannel.invokeMethod('stopEmdkScan').catchError((e) {
      debugPrint('Erreur arret EMDK: $e');
    });
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final qcState = ref.watch(qcProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F4F4),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(qcState),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Bouton retour
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
              // Icône QC animée
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) =>
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: .12 + .06 * _pulseCtrl.value),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .3)),
                      ),
                      child: const Icon(Icons.fact_check_rounded,
                          color: Colors.white, size: 20),
                    ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'QC RFID',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .4,
                    ),
                  ),
                  Text(
                    'Quality Control',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: .7),
                    ),
                  ),
                ],
              ),

              const Spacer(),
              _buildReaderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderButton() {
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
              connected != null ? 'Connected' : 'Disconnected',
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
                const Text(
                  'RFID Reader',
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
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF3949AB), size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (uniqueReaders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No reader available',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
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
                          ? const Color(0xFF2E7D32).withValues(alpha: .06)
                          : const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.nfc_rounded,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1A1A2E),
                              )),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32), size: 16),
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
  // ── Corps principal ───────────────────────────────────────

  Widget _buildBody(QcState qcState) {
    // Chargement
    if (qcState.isLoading) {
      return _buildLoadingState(qcState);
    }

    // Erreur
    if (qcState.error != null) {
      return _buildErrorState(qcState.error!);
    }

    // Colis chargés → afficher le choix du mode
    if (qcState.production != null) {
      return _buildModeSelection(qcState.production!);
    }

    // État initial → attente scan
    return _buildScanWaiting();
  }

  // ── État : Attente scan ───────────────────────────────────

  Widget _buildScanWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône animée
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) =>
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB)
                          .withValues(alpha: .08 + .04 * _pulseCtrl.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3949AB)
                            .withValues(alpha: .2 + .1 * _pulseCtrl.value),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 40,
                      color: Color(0xFF3949AB),
                    ),
                  ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan the article code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Point the DataWedge scanner\ntoward the article barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Instructions
            _buildInfoCard(
              icon: Icons.info_outline_rounded,
              text: 'Scanning the barcode will '
                  'automatically retrieve the list of associated parcels.',
            ),
          ],
        ),
      ),
    );
  }

  // ── État : Chargement ─────────────────────────────────────

  Widget _buildLoadingState(QcState qcState) {
    final step = qcState.isLoadingArticle
        ? 'Retrieving model code...'
        : 'Loading parcels...';

    final sub = qcState.isLoadingArticle
        ? 'Barcode : ${qcState.scannedGencode}'
        : 'Model code : ${qcState.codeMod}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3949AB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              step,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ── État : Erreur ─────────────────────────────────────────

  Widget _buildErrorState(String error) {
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
            const Text(
              'An error occurred',
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
              onPressed: () => ref.read(qcProvider.notifier).reset(),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: const Text('Scan again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
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

  // ── Choix du mode ─────────────────────────────────────────

  Widget _buildModeSelection(QcProductionModel production) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carte article
          _buildArticleSummaryCard(production),
          const SizedBox(height: 16),
          // ── Boutons Scan colis + Full Control ──
          Row(
            children: [
              // Bouton Commencer le scan
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _scanColisMode = true);
                    _showScanPopup();
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text(
                    'Scan Parcel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Bouton Full Control
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(qcProvider.notifier).selectMode(QcControlMode.full);
                    ref.read(qcProvider.notifier).prepareFullControl();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                        const QcInventoryPage(mode: QcControlMode.full),
                        transitionsBuilder: (_, anim, __, child) => SlideTransition(
                          position: Tween<Offset>(
                              begin: const Offset(1, 0), end: Offset.zero)
                              .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_rounded, size: 16),
                  label: const Text(
                    'Full Control',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Liste des colis (inchangée) ──
          _buildColisListPartiel(production.colis),
        ],
      ),
    );
  }

  // ── Carte résumé article ──────────────────────────────────

  Widget _buildArticleSummaryCard(QcProductionModel production) {
    final totalColis = production.colis.length;
    final totalArticles = production.colis.fold<int>(
        0, (sum, c) => sum + c.tailles.fold<int>(0, (s, t) => s + t.qte));
    final codeMod = ref
        .read(qcProvider)
        .codeMod ?? '';
    final imageUrl = ArticleService().getPhotoUrl(codeMod);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_not_supported_rounded,
                        color: Color(0xFF9FA8DA), size: 24),
                  ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF3949AB)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${production.marque}  •  ${production.famille}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${production.saison}  •  ${production.rayon}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: _buildStatChip(
                        label: 'Assortments',
                        value: '${production.colis.length}',
                        color: const Color(0xFF3949AB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildStatChip(
                        label: 'Pairs',
                        value: '${production.colis.fold<int>(0, (sum, c) => sum + c.nbArt)}',
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScanPopup() {
    if (_sheetController != null) return;

    _sheetController = _scaffoldKey.currentState!.showBottomSheet(
          (_) => _buildScanBottomSheet(),
      backgroundColor: Colors.transparent,
    );

    _sheetController!.closed.then((_) {
      _sheetController = null;
      if (mounted) setState(() => _scanColisMode = false);
    });
  }

  Widget _buildScanBottomSheet() {
    return Consumer(
      builder: (context, ref, _) {
        final qcState = ref.watch(qcProvider);
        final scannedCount = qcState.scannedColisCount;
        final totalUnites = scannedCount.values.fold(0, (s, v) => s + v);
        final isConnected = ref.watch(rfidProvider).connectedReader != null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF3949AB).withOpacity(.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + titre
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: Color(0xFF3949AB), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Colis sélectionnés',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const Spacer(),
                  // Badge total
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB).withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalUnites unité${totalUnites > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3949AB)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton fermer
                  GestureDetector(
                    onTap: () => _sheetController?.close(),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.grey, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Liste des colis scannés
              if (scannedCount.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Aucun colis scanné — pointez le scanner',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ...scannedCount.entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF3949AB).withOpacity(.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded,
                          color: Color(0xFF3949AB), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      // Badge ×N si scanné plusieurs fois
                      if (entry.value > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3949AB).withOpacity(.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '×${entry.value}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3949AB)),
                          ),
                        ),
                      // Bouton supprimer
                      GestureDetector(
                        onTap: () => ref
                            .read(qcProvider.notifier)
                            .removeScanColis(entry.key),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Color(0xFFD32F2F), size: 14),
                        ),
                      ),
                    ],
                  ),
                )),

              const SizedBox(height: 12),

              // Avertissement si pas de lecteur
              if (!isConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD32F2F).withOpacity(.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD32F2F), size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connectez un lecteur RFID avant de lancer.',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bouton lancer inventaire
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isConnected && scannedCount.isNotEmpty)
                      ? () {
                    _sheetController?.close();
                    ref
                        .read(qcProvider.notifier)
                        .selectMode(QcControlMode.partiel);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const QcInventoryPage(
                            mode: QcControlMode.partiel),
                        transitionsBuilder: (_, anim, __, child) =>
                            SlideTransition(
                              position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero)
                                  .animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                        transitionDuration:
                        const Duration(milliseconds: 300),
                      ),
                    );
                  }
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    scannedCount.isEmpty
                        ? 'Scannez au moins un colis'
                        : 'Lancer le contrôle RFID ($totalUnites colis)',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: .7)),
          ),
        ],
      ),
    );
  }
  Widget _buildColisListPartiel(List<QcColis> colisList) {
    final qcState = ref.watch(qcProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colisList.asMap().entries.map((entry) {
          final index = entry.key;
          final colis = entry.value;

          return GestureDetector(
            onTap: () {
              ref.read(qcProvider.notifier).selectMode(QcControlMode.partiel);
              ref.read(qcProvider.notifier).selectColis(colis);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, _, _) =>
                  const QcInventoryPage(mode: QcControlMode.partiel),
                  transitionsBuilder: (_, anim, _, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: _buildAssortimentCard(colis, index),
          );
        }),
      ],
    );
  }

  Widget _buildAssortimentCard(QcColis colis, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3949AB).withValues(alpha: .12)),
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF3949AB).withValues(alpha: .12)),
              ),
            ),
            child: Row(
              children: [
                // Numéro assortiment
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Color(0xFF3949AB),
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Code colis
                Expanded(
                  child: Text(
                    colis.codeColis,
                    style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .3),
                  ),
                ),
                // NbCol badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          color: Color(0xFF3949AB), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${colis.tailles.fold<int>(0, (s, t) => s + t.qte)} articles',
                        style: const TextStyle(
                            color: Color(0xFF3949AB),
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          // ── Tailles / Quantités ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(
                  color: const Color(0xFF93A3F6).withValues(alpha: .25),
                  width: 1,
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF0F2FF)),
                    children: colis.tailles.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: Text(
                        t.taille,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3949AB)),
                      ),
                    )).toList(),
                  ),
                  TableRow(
                    children: colis.tailles.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(
                        '${t.qte}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E)),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          // ── Image carton 3D ──
          if (colis.img.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFF3949AB).withValues(alpha: .08)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Image carton
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Builder(
                        builder: (_) {
                          try {
                            final bytes = _hexToBytes(colis.img.trim());
                            return Image.memory(
                              bytes,
                              height: 80,
                              fit: BoxFit.contain,
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Badge nb articles
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: .25)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${colis.nbCol}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const Text(
                            'parcels',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  // ── Info card
  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9FA8DA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3949AB), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF283593),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}