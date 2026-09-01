// =============================================================================
// CapMobile — Widget Previews — Module Swapp
// -----------------------------------------------------------------------------
// @Preview pour le menu SWApp et composants associés.
// Auteur : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/pages/menu/swapp_menu_page.dart';
import 'package:cap_mobile/swapp/pages/produit/swapp_infos_produit_menu_page.dart';
import 'package:cap_mobile/widget_previews/preview_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Preview IDE — menu SWApp plein écran (390×844).
@Preview(
  name: 'SWApp · Menu principal',
  group: 'Swapp',
  size: Size(390, 844),
  theme: capMobilePreviewTheme,
  localizations: capMobilePreviewLocalizations,
  wrapper: capMobilePreviewWrapper,
)
Widget swappMenuPagePreview() => const SwappMenuPage();

/// Preview IDE — menu SWApp format compact (360×720).
@Preview(
  name: 'SWApp · Menu (compact)',
  group: 'Swapp',
  size: Size(360, 720),
  theme: capMobilePreviewTheme,
  localizations: capMobilePreviewLocalizations,
  wrapper: capMobilePreviewWrapper,
)
Widget swappMenuPageCompactPreview() => const SwappMenuPage();

/// Preview IDE — menu Infos produit legacy (390×844).
@Preview(
  name: 'SWApp · Infos produit',
  group: 'Swapp',
  size: Size(390, 844),
  theme: capMobilePreviewTheme,
  localizations: capMobilePreviewLocalizations,
  wrapper: capMobilePreviewWrapper,
)
Widget swappInfosProduitMenuPreview() => const SwappInfosProduitMenuPage();
