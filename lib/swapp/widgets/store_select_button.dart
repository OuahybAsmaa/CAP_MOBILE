// =============================================================================
// CapMobile — Module Swapp — Bouton sélection magasin
// -----------------------------------------------------------------------------
// Fonctionnalité : Ouvre le picker magasin ; tooltip = nom du magasin courant.
// Design         : Bouton carré icône-only (store_rounded) ; dégradé primarySoft ;
//                  bordure bleue légère ; ombre subtile.
// UI             : Extrémité droite ligne 3 hero card — tooltip = nom magasin ;
//                  tap → showStorePickerDialog modal.
// Spécifications : [size] et [iconSize] passés par le layout parent ; haptic au tap.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton icône magasin — déclenche [onTap] pour afficher le dialogue de sélection.
class StoreSelectButton extends StatelessWidget {
  final String? tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const StoreSelectButton({
    super.key,
    this.tooltip,
    required this.onTap,
    required this.size,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.white,
        elevation: 0,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primarySoft,
                  AppColors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.store_rounded,
              size: iconSize,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
