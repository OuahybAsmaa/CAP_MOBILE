// =============================================================================
// CapMobile — Widget Previews — Réassort chip
// -----------------------------------------------------------------------------
// @Preview pour ReassortChip hero produit.
// Auteur : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/widgets/reassort_chip.dart';
import 'package:cap_mobile/widget_previews/preview_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Preview IDE — ReassortChip vert (réassort OK).
@Preview(
  name: 'Réassort · OK',
  group: 'Produit',
  size: Size(200, 48),
  theme: capMobilePreviewTheme,
  wrapper: capMobileLightPreviewWrapper,
)
Widget reassortChipOkPreview() {
  return ReassortChip(ok: true, dp: previewDp, sp: previewSp);
}

/// Preview IDE — ReassortChip rouge (réassort KO).
@Preview(
  name: 'Réassort · KO',
  group: 'Produit',
  size: Size(200, 48),
  theme: capMobilePreviewTheme,
  wrapper: capMobileLightPreviewWrapper,
)
Widget reassortChipKoPreview() {
  return ReassortChip(ok: false, dp: previewDp, sp: previewSp);
}
