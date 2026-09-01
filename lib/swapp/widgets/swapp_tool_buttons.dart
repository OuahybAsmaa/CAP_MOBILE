// =============================================================================
// CapMobile — Module Swapp — Boutons d'action ronds (toolbar partagée)
// -----------------------------------------------------------------------------
// Fonctionnalité : Barre d'actions commune — grille article, ranger, NFC, scan QR.
// Design         : Reprise exacte de _CompactToolbar (DetailProduitPage) —
//                  cercles pleins colorés, icône blanche, opacité si désactivé.
// UI             : Utilisée par InfoTarifArticlesPage et InfoOtPage pour garder
//                  la même barre que la fiche produit.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton rond plein — même rendu que la toolbar de la fiche produit.
class SwappToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final bool highlighted;
  final String? tooltip;

  const SwappToolButton({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    this.onTap,
    this.highlighted = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    final button = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: color,
        elevation: highlighted ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!.call();
                }
              : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: AppColors.white, size: size * 0.47),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Toolbar 4 actions — identique à la fiche produit (grille, ranger, NFC, QR).
class SwappCompactToolbar extends StatelessWidget {
  final double buttonSize;
  final double gap;
  final VoidCallback? onArticleSearch;
  final VoidCallback? onRanger;
  final VoidCallback? onNfc;
  final VoidCallback? onQrScan;
  final bool rangerActive;

  const SwappCompactToolbar({
    super.key,
    required this.buttonSize,
    required this.gap,
    this.onArticleSearch,
    this.onRanger,
    this.onNfc,
    this.onQrScan,
    this.rangerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwappToolButton(
          icon: Icons.apps_rounded,
          color: AppColors.error,
          size: buttonSize,
          onTap: onArticleSearch,
          tooltip: 'Recherche article',
        ),
        SizedBox(width: gap),
        SwappToolButton(
          icon: Icons.move_to_inbox_rounded,
          color: AppColors.success,
          size: buttonSize,
          onTap: onRanger,
          highlighted: rangerActive,
          tooltip: 'Ranger',
        ),
        SizedBox(width: gap),
        SwappToolButton(
          icon: Icons.nfc_rounded,
          color: AppColors.warning,
          size: buttonSize,
          onTap: onNfc,
          tooltip: 'NFC',
        ),
        SizedBox(width: gap),
        SwappToolButton(
          icon: Icons.qr_code_scanner_rounded,
          color: AppColors.primaryDark,
          size: buttonSize,
          onTap: onQrScan,
          tooltip: 'Scanner QR',
        ),
      ],
    );
  }
}
