// =============================================================================
// CapMobile — Widget Previews — Colis dépôt
// -----------------------------------------------------------------------------
// @Preview pour le bouton colis et les chips.
// Auteur : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/produit/data/product_test_data.dart';
import 'package:cap_mobile/swapp/widgets/colis_depot_chips.dart';
import 'package:cap_mobile/widget_previews/preview_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Preview IDE — bouton colis actif avec badge (2 colis en attente).
@Preview(
  name: 'Colis · Bouton actif',
  group: 'Colis dépôt',
  size: Size(120, 80),
  theme: capMobilePreviewTheme,
  wrapper: capMobileLightPreviewWrapper,
)
Widget colisDepotPackButtonPreview() {
  return ColisDepotPackButton(
    pendingCount: 2,
    dp: previewDp,
    sp: previewSp,
    visible: true,
    onTap: () {},
  );
}

/// Preview IDE — bouton colis masqué (aucun colis en attente).
@Preview(
  name: 'Colis · Bouton masqué',
  group: 'Colis dépôt',
  size: Size(120, 40),
  theme: capMobilePreviewTheme,
  wrapper: capMobileLightPreviewWrapper,
)
Widget colisDepotPackButtonHiddenPreview() {
  return const ColisDepotPackButton(
    pendingCount: 0,
    dp: previewDp,
    sp: previewSp,
    visible: false,
    onTap: _noop,
  );
}

/// Preview IDE — aperçu des chips démo (Wrap statique, sans popup).
@Preview(
  name: 'Colis · Chips démo',
  group: 'Colis dépôt',
  size: Size(390, 160),
  theme: capMobilePreviewTheme,
  wrapper: capMobileLightPreviewWrapper,
)
Widget colisDepotChipsWrapPreview() {
  final chips = demoColisDepotChips();
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          Chip(
            avatar: Icon(
              chip.isDepotResa
                  ? Icons.lock_open_rounded
                  : Icons.inventory_2_outlined,
              size: 16,
            ),
            label: Text(
              chip.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    ),
  );
}

/// Callback vide — évite const sur ColisDepotPackButton dans la preview masquée.
void _noop() {}
