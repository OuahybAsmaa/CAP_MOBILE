import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/datawedge_service.dart';
import '../models/exp_model.dart';
import '../providers/exp_provider.dart';
import '../../../features/rfid/providers/rfid_provider.dart';
import 'exp_inventory_page.dart';

// ─────────────────────────────────────────────────────────────
//  PAGE PRINCIPALE — Contrôle EXP
// ─────────────────────────────────────────────────────────────

class ExpControlPage extends ConsumerStatefulWidget {
  const ExpControlPage({super.key});

  @override
  ConsumerState<ExpControlPage> createState() => _ExpControlPageState();
}

class _ExpControlPageState extends ConsumerState<ExpControlPage>
    with SingleTickerProviderStateMixin {

  StreamSubscription<String>? _scanSubscription;
  late final AnimationController _pulseCtrl;
  final TextEditingController _magController = TextEditingController();
  bool get _magValid => _magController.text.trim().isNotEmpty &&
      int.tryParse(_magController.text.trim()) != null;

  static const _indigo    = Color(0xFF1A237E);
  static const _indigoMid = Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Reset à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expProvider.notifier).reset();
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
      final s         = ref.read(expProvider);
      final rfid      = ref.read(rfidProvider);
      final isReady   = rfid.connectedReader != null && !rfid.isLoading;

      if (!s.isLoadingRecep && _magValid && isReady) {
        ref.read(expProvider.notifier).reset();
        ref.read(expProvider.notifier).onCodeScanned(
          data,
          _magController.text.trim(),
        );
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _magController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(expProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(s)),
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
          colors: [_indigo, _indigoMid],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Retour
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
              // Icône animée
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
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CONTRÔLE EXP',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .4,
                    ),
                  ),
                  Text(
                    'Réception · Expédition',
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

  Widget _buildBody(ExpState s) {
    if (s.isLoadingRecep)  return _buildLoading(s);
    if (s.error != null)   return _buildError(s.error!);
    if (s.reception != null) return _buildReceptionCard(s);
    return _buildScanWaiting();
  }

  // ── État : attente scan ───────────────────────────────────

  Widget _buildScanWaiting() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Champ code magasin ──
          _buildMagInput(),
          const SizedBox(height: 24),

          // ── Zone scan (désactivée si mag pas valide) ──
          AnimatedOpacity(
            opacity: _magValid ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) => Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: _indigoMid
                          .withValues(alpha: .08 + .04 * _pulseCtrl.value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _indigoMid
                            .withValues(alpha: .2 + .1 * _pulseCtrl.value),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        size: 40, color: _indigoMid),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scanner le code d\'export',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _magValid
                      ? 'Pointez le scanner DataWedge\nvers le code-barres de réception'
                      : 'Entrez d\'abord le code magasin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  icon: Icons.info_outline_rounded,
                  text: 'Le scan du code réception affiche automatiquement '
                      'les articles attendus dans ce colis.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagInput() {
    final isConnected = ref.watch(rfidProvider).connectedReader != null;
    final isLoading   = ref.watch(rfidProvider).isLoading;
    final isReady     = isConnected && !isLoading;

    return AnimatedOpacity(
      opacity: isReady ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: AbsorbPointer(
        absorbing: !isReady,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label au dessus ──
            const Row(
              children: [
                Icon(Icons.store_rounded, color: _indigoMid, size: 16),
                SizedBox(width: 6),
                Text(
                  'Code magasin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Champ ──
            TextField(
              controller: _magController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0000',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3949AB), width: 1.5),
                ),
                suffixIcon: _magController.text.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    _magController.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Colors.grey),
                )
                    : null,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── État : chargement ─────────────────────────────────────

  Widget _buildLoading(ExpState s) {
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
                color: _indigoMid,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chargement de la réception...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Code : ${s.scannedCode}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ── État : erreur ─────────────────────────────────────────

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
            const Text(
              'Une erreur est survenue',
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
              onPressed: () =>
                  ref.read(expProvider.notifier).reset(),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: const Text('Scanner à nouveau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _indigoMid,
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

  // ── Carte réception ───────────────────────────────────────

  Widget _buildReceptionCard(ExpState s) {
    final r = s.reception!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Infos réception ──
          _buildReceptionInfoCard(r),
          const SizedBox(height: 14),

          // ── Liste des articles attendus ──
          _buildLignesPreview(r),
          const SizedBox(height: 20),

          // ── Bouton lancer le contrôle ──
          _buildLaunchButton(s),
        ],
      ),
    );
  }

  Widget _buildReceptionInfoCard(expReceptionModel) {
    final r = expReceptionModel;
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
          // Code réception + badge EXP
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded,
                  color: _indigoMid, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.codeRecep,
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
                  color: _indigoMid.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EXP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _indigoMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          // Expéditeur → Destinataire
          _buildTransferRow(
            icon: Icons.store_rounded,
            label: 'De',
            value: r.nomMag,
            color: const Color(0xFF5E35B1),
          ),
          const SizedBox(height: 8),
          Center(
            child: Icon(Icons.arrow_downward_rounded,
                color: Colors.grey[400], size: 16),
          ),
          const SizedBox(height: 8),
          _buildTransferRow(
            icon: Icons.store_mall_directory_rounded,
            label: 'Vers',
            value: r.nomMagDest,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          // Date + total articles
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: Color(0xFF757575)),
              const SizedBox(width: 6),
              Text(
                'Expédié le ${r.dateExpFormatted}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF757575)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.totalAttendu} article${r.totalAttendu > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferRow({
    required IconData icon,
    required String   label,
    required String   value,
    required Color    color,
  }) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500])),
            Text(value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildLignesPreview(ExpReceptionModel r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: r.lignes.map((l) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF93A3F6).withValues(alpha: .25),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Taille
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(7)),
                  ),
                  child: Text(
                    l.libTaille,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3949AB),
                    ),
                  ),
                ),
                // Quantité
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  child: Text(
                    '${l.qte}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildLaunchButton(ExpState s) {
    final connected =
        ref.read(rfidProvider).connectedReader != null;

    return Column(
      children: [
        if (!connected)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFD32F2F).withValues(alpha: .3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD32F2F), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connectez un lecteur RFID avant de commencer.',
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
            onPressed: connected
                ? () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, _, _) =>
                const ExpInventoryPage(),
                transitionsBuilder:
                    (_, anim, _, child) => SlideTransition(
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
            icon: const Icon(Icons.nfc_rounded, size: 20),
            label: const Text('Lancer le contrôle RFID',
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

  // ── Info card ─────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String   text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9FA8DA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _indigoMid, size: 16),
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