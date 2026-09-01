// =============================================================================
// CapMobile — Module Swapp — Métrique affichée dans la courbe My Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Onglets « Score / Clients / Moy. » sous la note globale ;
//                  pilote la série tracée dans « Évolution ».
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter/material.dart';

/// Série tracée par le graphique d'évolution.
enum GoodaysMetric {
  score('Score', 'ÉVOLUTION DU SCORE', Icons.bar_chart_rounded),
  clients('Clients', 'ÉVOLUTION DES CLIENTS', Icons.people_alt_rounded),
  moyenne('Moy.', 'ÉVOLUTION DE LA MOYENNE', Icons.show_chart_rounded);

  /// Libellé court affiché dans l'onglet.
  final String label;

  /// Titre de la carte graphique quand la métrique est active.
  final String chartTitle;

  final IconData icon;

  const GoodaysMetric(this.label, this.chartTitle, this.icon);
}
