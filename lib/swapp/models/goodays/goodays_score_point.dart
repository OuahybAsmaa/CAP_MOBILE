// =============================================================================
// CapMobile — Module Swapp — Point de la courbe d'évolution My Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Une abscisse du graphique (une semaine, un mois...) avec les
//                  trois séries disponibles : score, nombre d'avis, moyenne.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/models/goodays/goodays_metric.dart';

/// Valeur d'une période élémentaire de la courbe (ex. « S23 »).
class GoodaysScorePoint {
  /// Libellé de l'axe des abscisses (« S23 », « Jan »...).
  final String label;

  /// Note moyenne de la période, sur 5.
  final double score;

  /// Nombre d'avis clients collectés sur la période.
  final int clients;

  /// Moyenne glissante (lissage sur les périodes précédentes).
  final double moyenne;

  const GoodaysScorePoint({
    required this.label,
    required this.score,
    required this.clients,
    required this.moyenne,
  });

  /// Valeur à tracer selon l'onglet sélectionné.
  double valueFor(GoodaysMetric metric) => switch (metric) {
    GoodaysMetric.score => score,
    GoodaysMetric.clients => clients.toDouble(),
    GoodaysMetric.moyenne => moyenne,
  };

  /// TODO(API) : brancher sur la réponse `/goodays/evolution`.
  factory GoodaysScorePoint.fromJson(Map<String, dynamic> json) {
    return GoodaysScorePoint(
      label: json['label']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      clients: (json['clients'] as num?)?.toInt() ?? 0,
      moyenne: (json['moyenne'] as num?)?.toDouble() ?? 0,
    );
  }
}
