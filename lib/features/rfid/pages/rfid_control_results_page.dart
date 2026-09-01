import 'rfid_tag_finder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/inventory_service.dart';
import '../../inventory/providers/control_provider.dart';
import 'rfid_constants.dart';

class RfidControlResultsPage extends ConsumerWidget {
  final VoidCallback onStop;

  const RfidControlResultsPage({super.key, required this.onStop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(controlProvider);
    final tags         = controlState.filteredTags;
    final mode         = controlState.selectedMode;

    Color accentColor;
    IconData accentIcon;
    String accentTitle;

    switch (mode) {
      case ControlMode.findUnknownTags:
        accentColor = const Color(0xFFF59E0B);
        accentIcon  = Icons.warning_amber_rounded;
        accentTitle = 'Puces vierges';
        break;
      case ControlMode.findEncodedTags:
        accentColor = AppColors.success;
        accentIcon  = Icons.verified_rounded;
        accentTitle = 'Puces encodées';
        break;
      case ControlMode.findAll:
        accentColor = AppColors.primary;
        accentIcon  = Icons.list_alt_rounded;
        accentTitle = 'Toutes les puces';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(accentIcon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(accentTitle,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          if (controlState.isRunning)
            TextButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded, color: Colors.redAccent, size: 16),
              label: const Text('Arrêter',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de stats ──
          // ── Barre de stats : afficher UNIQUEMENT ce qui est pertinent selon le mode ──
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (mode == ControlMode.findUnknownTags || mode == ControlMode.findAll)
                  _StatChip(
                    label: 'Vierges',
                    value: '${controlState.virginCount}',
                    color: const Color(0xFFF59E0B),
                  ),
                if (mode == ControlMode.findEncodedTags || mode == ControlMode.findAll)
                  ...[
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Encodées',
                      value: '${controlState.encodedCount}',
                      color: AppColors.success,
                    ),
                  ],
                if (mode == ControlMode.findAll) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Total',
                    value: '${controlState.uniqueCount}',
                    color: AppColors.primary,
                  ),
                ],
                const Spacer(),
                if (controlState.isRunning)
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('En cours',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),

          // ── Liste des tags ──
          Expanded(
            child: tags.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    controlState.isRunning
                        ? 'Scan en cours…'
                        : 'Aucun tag pour ce filtre',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: tags.length,
              separatorBuilder: (_, _) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _TagCard(tag: tags[i], accentColor: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip statistique ──
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TagCard extends StatelessWidget {
  final ControlTag tag;
  final Color accentColor;

  const _TagCard({required this.tag, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isVirgin = tag.isVirgin;
    final tagColor = isVirgin ? const Color(0xFFF59E0B) : AppColors.success;

    return GestureDetector(
        onTap: () {
          if (!isVirgin) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RfidTagFinderSheet(
              epc: tag.epc,
              service: InventoryService(),
            ),
          );
        },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône type
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVirgin ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: tagColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // EPC sur une seule ligne + badge statut
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tag.epc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: .2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagColor.withValues(alpha: .3)),
                  ),
                  child: Text(
                    isVirgin ? '🔍 Localiser' : 'Encodée',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tagColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}