// =============================================================================
// CapMobile — Module Swapp — Widget chip réassort
// -----------------------------------------------------------------------------
// Fonctionnalité : Indicateur réassort OK / en attente (i18n reorderOk / reorderPending).
// Design         : Chip arrondi vert/rouge ; icône + texte ; FittedBox si traduction longue.
// UI             : Coin haut-gauche hero card — à gauche de _CompactToolbar ;
//                  vert=check « Réassort OK », rouge=error « En attente ».
// Spécifications : [resolveReassortChipSizes] adapte fonte/icône selon largeur et longueur
//                  du libellé (ex. NL) pour éviter chevauchement avec la toolbar.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Tailles calculées pour le chip réassort (texte + icône).
class ReassortChipSizes {
  final double fontSize;
  final double iconSize;

  const ReassortChipSizes({
    required this.fontSize,
    required this.iconSize,
  });
}

ReassortChipSizes resolveReassortChipSizes({
  required double maxWidth,
  required String label,
  required double Function(double v) sp,
  required double Function(double v) dp,
}) {
  final long = label.length > 16;

  if (maxWidth >= 240) {
    return ReassortChipSizes(
      fontSize: sp(long ? 12 : 13),
      iconSize: dp(long ? 14 : 15),
    );
  }
  if (maxWidth >= 185) {
    return ReassortChipSizes(
      fontSize: sp(long ? 11 : 12),
      iconSize: dp(long ? 13 : 14),
    );
  }
  return ReassortChipSizes(
    fontSize: sp(long ? 10 : 11),
    iconSize: dp(long ? 12 : 13),
  );
}

/// Chip réassort — vert si OK, rouge si en attente ; tailles adaptatives.
class ReassortChip extends StatelessWidget {
  final bool ok;
  final double Function(double v) dp;
  final double Function(double v) sp;

  const ReassortChip({
    super.key,
    required this.ok,
    required this.dp,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = ok ? AppColors.success : AppColors.error;
    final label = ok ? l10n.reorderOk : l10n.reorderPending;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizes = resolveReassortChipSizes(
          maxWidth: constraints.maxWidth,
          label: label,
          sp: sp,
          dp: dp,
        );

        final chip = Container(
          padding: EdgeInsets.symmetric(
            horizontal: dp(8),
            vertical: dp(4),
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.error_outline,
                size: sizes.iconSize,
                color: color,
              ),
              SizedBox(width: dp(4)),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: sizes.fontSize,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: chip,
          ),
        );
      },
    );
  }
}
