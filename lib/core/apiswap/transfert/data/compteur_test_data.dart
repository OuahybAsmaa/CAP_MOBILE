// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/compteur_item.dart';

/// Données démo — compteurs disponibles pour le magasin.
abstract final class CompteurDemoData {
  static List<CompteurItem> items() => const [
    CompteurItem(numero: 999, libelleDepot: 'VGM TREMERY'),
  ];
}
