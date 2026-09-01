// =============================================================================
// CapMobile — Module Swapp — Données de démonstration avis Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Jeu local tant que l'API Goodays n'est pas branchée.
// Spécifications : REMPLACER par SwappApiService.fetchGoodaysAvis(since).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/models/goodays/goodays_avis.dart';

/// Fabrique d'avis de démonstration.
abstract final class GoodaysAvisDemoData {
  static List<GoodaysAvis> all() => [
    GoodaysAvis(
      id: '1',
      prenom: 'Martine',
      nom: 'MOSSON',
      nps: 3,
      date: _martine,
      commentaire: "Déçu qu'on ne rembourse pas un paiement en argent liquide",
      canal: 'Post achat',
      repondu: true,
      categorie: GoodaysAvisCategorie.negatif,
    ),
    GoodaysAvis(
      id: '2',
      prenom: 'Janine',
      nom: 'MATHIE',
      nps: 5,
      date: _janine,
      commentaire: 'La disponibilité du personnel et sa gentillesse',
      canal: 'Post achat',
      repondu: true,
      categorie: GoodaysAvisCategorie.positif,
    ),
    GoodaysAvis(
      id: '3',
      prenom: 'Philippe',
      nom: 'DURAND',
      nps: 9,
      date: _philippe,
      commentaire: 'Très bon accueil et conseils pertinents en rayon',
      canal: 'Post achat',
      repondu: false,
      categorie: GoodaysAvisCategorie.positif,
    ),
    GoodaysAvis(
      id: '4',
      prenom: 'Sophie',
      nom: 'LEFEVRE',
      nps: 2,
      date: _sophie,
      commentaire: 'Attente trop longue en caisse un samedi après-midi',
      canal: 'Post achat',
      repondu: false,
      categorie: GoodaysAvisCategorie.negatif,
    ),
  ];

  static final _martine = DateTime(2026, 8, 24, 14, 19, 7);
  static final _janine = DateTime(2026, 8, 21, 13, 52, 20);
  static final _philippe = DateTime(2026, 8, 19, 10, 15, 0);
  static final _sophie = DateTime(2026, 8, 18, 16, 40, 33);
}
