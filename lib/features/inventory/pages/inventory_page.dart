import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import 'tags_detail_page.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS — identiques à HomePage
// ──────────────────────────────────────────────────────────────
class _C {
  static const bg            = Color(0xFFDCF4F8);
  static const surface       = Color(0xFFFFFFFF);
  static const primary       = Color(0xFF0070F3);
  static const primaryDark   = Color(0xFF1E40AF);
  static const primarySoft   = Color(0xFFEBF5FF);
  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFD1D5DB);
}

// ──────────────────────────────────────────────────────────────
//  PAGE INVENTAIRE
// ──────────────────────────────────────────────────────────────
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  Timer? _batteryTimer;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    // Animation pulsation pour le bouton actif
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadAvailableReaders();
      ref.read(inventoryProvider.notifier).refreshBattery();
    });

    // Rafraîchir la batterie toutes les 30 secondes
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(inventoryProvider.notifier).refreshBattery();
    });
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    // Lancer / arrêter la pulsation selon l'état
    if (state.isRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!state.isRunning && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildTopBar(context, state),
            if (state.error != null) _buildErrorBanner(state.error!),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    _buildReaderCard(state),
                    const SizedBox(height: 16),
                    _buildStatusCard(state),
                    const SizedBox(height: 20),
                    _buildStatsGrid(state),
                    const SizedBox(height: 24),
                    _buildStartStopButton(state),
                    const SizedBox(height: 16),
                    _buildViewTagsButton(state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderCard(InventoryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: state.connectedReader != null
              ? _C.success.withOpacity(.3)
              : _C.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: state.connectedReader != null
                  ? _C.success.withOpacity(.1)
                  : _C.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              state.connectedReader != null
                  ? Icons.nfc_rounded
                  : Icons.nfc_outlined,
              color: state.connectedReader != null ? _C.success : _C.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: state.isConnecting
                ? const Row(children: [
              SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Connexion...'),
            ])
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.connectedReader,
                hint: const Text('Choisir un lecteur'),
                items: state.availableReaders
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (name) {
                  if (name == null) return;
                  if (state.connectedReader != null) {
                    ref.read(inventoryProvider.notifier).disconnectReader();
                  }
                  ref.read(inventoryProvider.notifier).connectToReader(name);
                },
              ),
            ),
          ),
          if (state.connectedReader != null)
            GestureDetector(
              onTap: () =>
                  ref.read(inventoryProvider.notifier).disconnectReader(),
              child: const Icon(Icons.close_rounded, color: _C.error, size: 18),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                ref.read(inventoryProvider.notifier).loadAvailableReaders(),
            child: const Icon(Icons.refresh_rounded, color: _C.primary, size: 18),
          ),
        ],
      ),
    );
  }
  // ────────────────────────────────────────────────────────────
  //  TOP BAR — style HomePage
  // ────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, InventoryState state) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // ── Bouton retour ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _C.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Titre ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVENTAIRE RFID',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _C.primaryDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Stock & localisation RSSI',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textMuted,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Batterie ──
              _buildBatteryWidget(state.batteryLevel),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  BATTERIE
  // ────────────────────────────────────────────────────────────
  Widget _buildBatteryWidget(int level) {
    if (level == -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _C.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.battery_unknown, color: _C.textMuted, size: 20),
      );
    }

    IconData icon;
    Color color;

    if (level >= 80) {
      icon  = Icons.battery_full;
      color = _C.success;
    } else if (level >= 50) {
      icon  = Icons.battery_5_bar;
      color = const Color(0xFF34D399);
    } else if (level >= 20) {
      icon  = Icons.battery_3_bar;
      color = _C.warning;
    } else {
      icon  = Icons.battery_1_bar;
      color = _C.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  CARTE STATUT
  // ────────────────────────────────────────────────────────────
  Widget _buildStatusCard(InventoryState state) {
    final isRunning = state.isRunning;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final glowOpacity = isRunning
            ? 0.15 + (_pulseCtrl.value * 0.15)
            : 0.08;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isRunning
                  ? [_C.primaryDark, _C.primary]
                  : [const Color(0xFF374151), const Color(0xFF4B5563)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isRunning ? _C.primary : Colors.black)
                    .withOpacity(glowOpacity),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône statut
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isRunning
                      ? Icons.wifi_tethering_rounded
                      : Icons.wifi_tethering_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? 'Inventaire en cours' : 'Inventaire arrêté',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRunning
                          ? 'Lecture des tags RFID active…'
                          : 'Appuyez sur Démarrer pour lancer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.75),
                      ),
                    ),
                  ],
                ),
              ),
              // Indicateur actif
              if (isRunning)
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _C.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.success
                              .withOpacity(0.4 + _pulseCtrl.value * 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  //  GRILLE STATISTIQUES — style carte HomePage
  // ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(InventoryState state) {
    final stats = [
      _StatItem(
        label: 'Total Reads',
        value: '${state.totalReads}',
        icon: Icons.tag_rounded,
        color: _C.primary,
        bgColor: _C.primarySoft,
      ),
      _StatItem(
        label: 'Tags Uniques',
        value: '${state.uniqueTags}',
        icon: Icons.fiber_smart_record_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ),
      _StatItem(
        label: 'Cadence',
        value: '${state.readRate.toStringAsFixed(1)}/s',
        icon: Icons.speed_rounded,
        color: _C.warning,
        bgColor: const Color(0xFFFFFBEB),
      ),
      _StatItem(
        label: 'Durée',
        value: _formatDuration(state.readTime),
        icon: Icons.timer_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: item.color,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: _C.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  BOUTON DÉMARRER / ARRÊTER
  // ────────────────────────────────────────────────────────────
  Widget _buildStartStopButton(InventoryState state) {
    final isRunning = state.isRunning;

    return GestureDetector(
      onTap: () {
        if (isRunning) {
          ref.read(inventoryProvider.notifier).stopInventory();
        } else {
          ref.read(inventoryProvider.notifier).startInventory();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRunning
                ? [_C.error, const Color(0xFFDC2626)]
                : [_C.primaryDark, _C.primary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isRunning ? _C.error : _C.primary).withOpacity(.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isRunning ? "Arrêter l'inventaire" : "Démarrer l'inventaire",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  BOUTON VOIR TAGS
  // ────────────────────────────────────────────────────────────
  Widget _buildViewTagsButton(InventoryState state) {
    final hasData = state.tags.isNotEmpty;

    return GestureDetector(
      onTap: hasData
          ? () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const TagsDetailPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      )
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hasData ? 1.0 : 0.45,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasData
                  ? _C.primary.withOpacity(.3)
                  : _C.border,
            ),
            boxShadow: hasData
                ? [
              BoxShadow(
                color: _C.primary.withOpacity(.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: _C.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasData
                    ? 'Voir les ${state.uniqueTags} tag(s) lus'
                    : 'Aucun tag pour le moment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: hasData ? _C.primary : _C.textMuted,
                ),
              ),
              if (hasData) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _C.primary,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  BANNIÈRE ERREUR
  // ────────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.error.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.error.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _C.error.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: _C.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: _C.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(inventoryProvider.notifier).reset(),
            child: const Icon(Icons.close_rounded,
                color: _C.error, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Helper ──
  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ──────────────────────────────────────────────────────────────
//  Modèle interne pour les cartes stats
// ──────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}