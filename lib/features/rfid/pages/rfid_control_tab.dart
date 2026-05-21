import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../inventory/providers/control_provider.dart';
import '../providers/rfid_provider.dart';
import 'rfid_constants.dart';
import 'rfid_control_results_page.dart';

// ──────────────────────────────────────────────────────────────
//  RFID CONTROL TAB
// ──────────────────────────────────────────────────────────────
class RfidControlTab extends ConsumerStatefulWidget {
  const RfidControlTab({Key? key}) : super(key: key);

  @override
  ConsumerState<RfidControlTab> createState() => _RfidControlTabState();
}

class _RfidControlTabState extends ConsumerState<RfidControlTab>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlState = ref.watch(controlProvider);

    // ── Lecteur partagé depuis rfidProvider ──
    final rfidState      = ref.watch(rfidProvider);
    final connectedReader = rfidState.connectedReader; // même objet que l'onglet Encodage

    // Pulsation pendant le scan
    if (controlState.isRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!controlState.isRunning && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            step: 1,
            title: 'Type de contrôle',
            child: _buildModeSelector(controlState),
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            step: 2,
            title: 'Lancer l\'inventaire',
            child: _buildControlLaunchSection(controlState, connectedReader),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SÉLECTEUR DE MODE
  // ══════════════════════════════════════════════════════════════
  Widget _buildModeSelector(ControlState controlState) {
    final isDisabled = controlState.isRunning;

    Color accentColor;
    switch (controlState.selectedMode) {
      case ControlMode.findUnknownTags:
        accentColor = const Color(0xFFF59E0B);
        break;
      case ControlMode.findEncodedTags:
        accentColor = AppColors.success;
        break;
      case ControlMode.findAll:
        accentColor = AppColors.primary;
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.bg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ControlMode>(
            value: controlState.selectedMode,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: isDisabled ? AppColors.textMuted : accentColor, size: 18),
            onChanged: isDisabled
                ? null
                : (mode) {
              if (mode != null) {
                ref.read(controlProvider.notifier).setMode(mode);
              }
            },
            selectedItemBuilder: (_) => ControlMode.values.map((mode) {
              return Row(
                children: [
                  Text(mode.iconDescription, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(mode.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accentColor),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              );
            }).toList(),
            items: ControlMode.values.map((mode) {
              final isSelected = controlState.selectedMode == mode;
              Color itemColor;
              switch (mode) {
                case ControlMode.findUnknownTags:
                  itemColor = const Color(0xFFF59E0B);
                  break;
                case ControlMode.findEncodedTags:
                  itemColor = AppColors.success;
                  break;
                case ControlMode.findAll:
                  itemColor = AppColors.primary;
                  break;
              }
              return DropdownMenuItem<ControlMode>(
                value: mode,
                child: Row(
                  children: [
                    Text(mode.iconDescription, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mode.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? itemColor : AppColors.textPrimary)),
                          Text(mode.description,
                              style: const TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.3),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: itemColor, size: 14),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SECTION LANCEMENT
  // ══════════════════════════════════════════════════════════════
  Widget _buildControlLaunchSection(
      ControlState controlState, dynamic connectedReader) {
    final isConnected = connectedReader != null;
    final isRunning   = controlState.isRunning;

    return Column(
      children: [
        if (isRunning || controlState.allTags.isNotEmpty) ...[
          _buildQuickStats(controlState),
          const SizedBox(height: 8),
        ],

        // ── Bouton Start / Stop ──
        GestureDetector(
          onTap: () {
            if (!isConnected && !isRunning) {
              _showNoReaderSnackbar();
              return;
            }
            if (isRunning) {
              ref.read(controlProvider.notifier).stopControl();
            } else {
              ref.read(controlProvider.notifier).reset();
              ref.read(controlProvider.notifier).startControl(connectedReader.name as String);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RfidControlResultsPage(
                    onStop: () => ref.read(controlProvider.notifier).stopControl(),
                  ),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRunning
                    ? [AppColors.error, const Color(0xFFDC2626)]
                    : isConnected
                    ? [AppColors.primaryDark, AppColors.primary]
                    : [AppColors.textMuted, AppColors.textMuted],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? AppColors.error : AppColors.primary)
                      .withOpacity(isConnected ? .3 : .1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRunning)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withOpacity(0.4 + _pulseCtrl.value * 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Icon(
                    isConnected
                        ? Icons.play_arrow_rounded
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 6),
                Text(
                  isRunning
                      ? 'Arrêter le contrôle'
                      : isConnected
                      ? 'Démarrer le contrôle'
                      : 'Connectez un lecteur (onglet Encodage)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bouton reset ──
        if (!isRunning && controlState.allTags.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => ref.read(controlProvider.notifier).reset(),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restart_alt_rounded,
                      color: AppColors.textMuted, size: 14),
                  SizedBox(width: 6),
                  Text('Réinitialiser',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],

        if (!isRunning && controlState.allTags.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RfidControlResultsPage(
                  onStop: () => ref.read(controlProvider.notifier).stopControl(),
                ),
              ),
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 15),
                  SizedBox(width: 6),
                  Text('Voir les résultats',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
        // ── Erreur ──
        if (controlState.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(controlState.error!,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.error)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  COMPTEURS RAPIDES
  // ══════════════════════════════════════════════════════════════
  Widget _buildQuickStats(ControlState controlState) {
    final items = [
      _QuickStat(label: 'Vierges',  value: '${controlState.virginCount}',
          color: const Color(0xFFF59E0B), icon: Icons.warning_amber_rounded),
      _QuickStat(label: 'Encodées', value: '${controlState.encodedCount}',
          color: AppColors.success,       icon: Icons.check_circle_rounded),
      _QuickStat(label: 'Total',    value: '${controlState.uniqueCount}',
          color: AppColors.primary,       icon: Icons.tag_rounded),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final s = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 6 : 0),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: s.color.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: s.color.withOpacity(.2)),
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: 14),
                const SizedBox(height: 3),
                Text(s.value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: s.color)),
                Text(s.label,
                    style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  UTILITAIRES
  // ══════════════════════════════════════════════════════════════
  Widget _buildStepCard(
      {required int step, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 1)),
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
                    color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Center(
                  child: Text('$step',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: .2)),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  void _showNoReaderSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Aucun lecteur connecté — allez dans l\'onglet Encodage pour en connecter un.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  MODÈLE INTERNE
// ──────────────────────────────────────────────────────────────
class _QuickStat {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _QuickStat(
      {required this.label,
        required this.value,
        required this.color,
        required this.icon});
}