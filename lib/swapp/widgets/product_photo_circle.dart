// =============================================================================
// CapMobile — Module Swapp — Widget photo produit
// -----------------------------------------------------------------------------
// Fonctionnalité : Affiche la photo produit ; bascule visibilité (œil) ;
//                  zoom plein écran au tap avec InteractiveViewer.
// Design         : Carré arrondi (radius ~16 %), ombre double, BoxFit.fill ;
//                  bouton œil bleu/blanc en haut à droite (_eyeRight / _eyeTop).
// UI             : Colonne droite _ProductHeroCard — carré photo + œil overlay ;
//                  tap photo → Dialog zoom ; tap œil → toggle showImage parent.
// Spécifications : [showImage] contrôle affichage ; placeholder si URL vide ;
//                  haptic feedback sur tap et toggle.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Photo produit — carré arrondi, ombre, zoom au tap et bouton œil.
class ProductPhotoCircle extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final bool showImage;
  final VoidCallback onToggleVisibility;
  final double eyeSize;

  const ProductPhotoCircle({
    super.key,
    required this.size,
    required this.photoUrl,
    required this.showImage,
    required this.onToggleVisibility,
    required this.eyeSize,
  });

  /// UI : Rayon coins carré photo (16 % de [size]).
  double get _radius => size * 0.16;

  /// UI : Position bouton œil sur la photo — modifier pour déplacer l'icône.
  /// `right` : distance bord droit ; `top` : distance depuis le haut.
  double get _eyeRight => size * 0.02;
  double get _eyeTop => size * 0.02;

  bool get _hasPhoto =>
      showImage && photoUrl != null && photoUrl!.trim().isNotEmpty;

  /// UI : Dialog plein écran semi-transparent — pinch-zoom InteractiveViewer.
  void _openZoom(BuildContext context) {
    if (!_hasPhoto) return;
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        width: 280,
                        height: 280,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white.withOpacity(0.85),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 280,
                      height: 280,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.22),
                  blurRadius: size * 0.16,
                  offset: Offset(0, size * 0.07),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: size * 0.05,
                  offset: Offset(0, size * 0.025),
                ),
              ],
            ),
            child: Material(
              color: AppColors.primarySoft,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: radius,
                onTap: _hasPhoto ? () => _openZoom(context) : null,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
          // Bouton œil : affiche / masque la photo produit.
          // Ajuster _eyeRight / _eyeTop plus haut dans ce fichier.
          Positioned(
            right: _eyeRight,
            top: _eyeTop,
            child: Material(
              color: AppColors.primary,
              elevation: 3,
              shadowColor: AppColors.primaryDark.withOpacity(0.45),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleVisibility();
                },
                child: SizedBox(
                  width: eyeSize,
                  height: eyeSize,
                  child: Icon(
                    showImage ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.white,
                    size: eyeSize * 0.56,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_hasPhoto) {
      return Image.network(
        photoUrl!,
        key: ValueKey('photo-$photoUrl'),
        width: size,
        height: size,
        fit: BoxFit.fill,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _placeholder('placeholder-error'),
      );
    }

    return _placeholder(showImage ? 'placeholder-on' : 'placeholder-off');
  }

  Widget _placeholder(String keyValue) {
    return Container(
      key: ValueKey(keyValue),
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_run_rounded,
        size: size * 0.38,
        color: AppColors.primaryDark.withOpacity(0.45),
      ),
    );
  }
}
