// =============================================================================
// CapMobile — Module Swapp — Dialogue saisie code article
// -----------------------------------------------------------------------------
// Fonctionnalité : Saisie manuelle du code modèle / article ; validation non vide.
// UI             : AppPopup.input — ouvert par le bouton grille de la fiche produit.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:flutter/material.dart';

/// Ouvre la saisie du code article. Retourne le code trimé, ou null si annulé.
Future<String?> showArticleCodeDialog(
  BuildContext context, {
  required String initialCode,
}) {
  final l10n = context.l10n;
  return AppPopup.input(
    context,
    icon: Icons.inventory_2_rounded,
    title: l10n.articleCodeTitle,
    message: l10n.articleCodeSubtitle,
    hint: l10n.articleCodeHint,
    initialValue: initialCode,
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.validate,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.search,
    validator: (value) => value.isEmpty ? l10n.articleCodeRequired : null,
  );
}
