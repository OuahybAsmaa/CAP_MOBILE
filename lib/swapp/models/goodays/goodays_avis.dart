// =============================================================================
// CapMobile — Module Swapp — Avis client Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Un avis client affiché dans GoodaysAvisPage — NPS, commentaire,
//                  canal (post achat…), statut de réponse.
// Spécifications : [fromJson] prêt pour l'API Goodays /feedbacks.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter/material.dart';

/// Catégorie visuelle de l'avis (icône à gauche du commentaire).
enum GoodaysAvisCategorie {
  negatif(Icons.payments_rounded),
  positif(Icons.add_rounded);

  final IconData icon;
  const GoodaysAvisCategorie(this.icon);
}

/// Avis client reçu via Goodays.
class GoodaysAvis {
  final String id;
  final String prenom;
  final String nom;
  final int nps;
  final DateTime date;
  final String commentaire;
  final String canal;
  final bool repondu;
  final GoodaysAvisCategorie categorie;

  const GoodaysAvis({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.nps,
    required this.date,
    required this.commentaire,
    required this.canal,
    required this.repondu,
    required this.categorie,
  });

  /// Initiales pour l'avatar (ex. « MM »).
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  String get nomComplet => '$prenom $nom';

  /// Couleur d'accent : détracteur ≤ 4, positif ≥ 5 (aligné maquette).
  bool get isPromoteur => nps >= 5;

  /// TODO(API) : brancher sur la réponse `/goodays/feedbacks`.
  factory GoodaysAvis.fromJson(Map<String, dynamic> json) {
    return GoodaysAvis(
      id: json['id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      nps: (json['nps'] as num).round(),
      date: DateTime.parse(json['date'] as String),
      commentaire: json['commentaire'] as String,
      canal: json['canal'] as String? ?? 'Post achat',
      repondu: json['repondu'] as bool? ?? false,
      categorie: json['categorie'] == 'POSITIF'
          ? GoodaysAvisCategorie.positif
          : GoodaysAvisCategorie.negatif,
    );
  }
}
