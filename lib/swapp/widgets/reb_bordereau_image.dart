// =============================================================================
// CapMobile — Swapp — Affichage d'un bordereau scanné
// -----------------------------------------------------------------------------
// Affiche une vignette de document (asset SVG/JPG, fichier local, ou URL HTTP).
// Utilisé par Mes remises et Ajouter une remise.
// =============================================================================

import 'dart:io';

import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Image d'un bordereau scanné — gère asset, fichier et réseau.
class RebBordereauImage extends StatelessWidget {
  final String? source;
  final BoxFit fit;

  const RebBordereauImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
  });

  bool get _empty => source == null || source!.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_empty) return const _Missing();

    final path = source!.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _Missing(),
      );
    }

    if (path.startsWith('assets/')) {
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          path,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          placeholderBuilder: (_) => const _Missing(),
        );
      }
      return Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _Missing(),
      );
    }

    // Chemin fichier local (photo prise à la caméra).
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _Missing(),
      );
    }

    return const _Missing();
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappMenuColors.p1Bg,
      child: Center(
        child: Icon(
          Icons.receipt_long_rounded,
          color: SwappMenuColors.p1,
          size: 28,
        ),
      ),
    );
  }
}
