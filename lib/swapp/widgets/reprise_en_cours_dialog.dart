// =============================================================================
// CapMobile — Module Swapp — Popup de reprise des saisies en cours
// -----------------------------------------------------------------------------
// Fonctionnalité : Demander à l'agent s'il poursuit ses saisies non clôturées
//                  (OT de transfert, retours dépôt) avant d'en démarrer une.
// Design         : AppPopup.choice — Oui vert / Non rouge.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:flutter/material.dart';

/// Affiche le popup de reprise — true si l'agent veut poursuivre ses saisies.
///
/// [uniteEnAttente] est le nom au singulier de la ligne comptée (« OT »,
/// « retour ») ; le pluriel est ajouté automatiquement.
Future<bool> showRepriseEnCoursDialog(
  BuildContext context, {
  required String message,
  required int nbEnAttente,
  required String uniteEnAttente,
  required int nbArticles,
  IconData icon = Icons.pending_actions_rounded,
}) {
  return AppPopup.choice(
    context,
    icon: icon,
    title: message,
    badge: '$nbEnAttente $uniteEnAttente${nbEnAttente > 1 ? 's' : ''} '
        'en attente · $nbArticles article${nbArticles > 1 ? 's' : ''}',
  );
}
