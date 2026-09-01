// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/article_saisie_item.dart';

/// Données démo — reproduction capture « Articles du transfert » legacy.
abstract final class ArticleSaisieDemoData {
  /// 7 lignes : 3 validées, 2 en alerte, 2 en attente.
  static List<ArticleSaisieItem> items() => const [
    ArticleSaisieItem(
      codeArticle: '30180098',
      taille: 'T-39',
      couleur: 'Rouge',
      stock: 0,
      quantite: 2,
      statut: ArticleSaisieStatut.valide,
    ),
    ArticleSaisieItem(
      codeArticle: '91510311',
      taille: 'T-41',
      couleur: 'Noir',
      stock: 0,
      quantite: 1,
      statut: ArticleSaisieStatut.alerte,
    ),
    ArticleSaisieItem(
      codeArticle: '30180098',
      taille: 'T-38',
      couleur: 'Rouge',
      stock: 0,
      quantite: 3,
      statut: ArticleSaisieStatut.enAttente,
    ),
    ArticleSaisieItem(
      codeArticle: '91510278',
      taille: 'T-41',
      couleur: 'Rose',
      stock: 0,
      quantite: 1,
      statut: ArticleSaisieStatut.valide,
    ),
    ArticleSaisieItem(
      codeArticle: '30180098',
      taille: 'T-37',
      couleur: 'Rouge',
      stock: 0,
      quantite: 1,
      statut: ArticleSaisieStatut.alerte,
    ),
    ArticleSaisieItem(
      codeArticle: '91510278',
      taille: 'T-36',
      couleur: 'Rose',
      stock: 0,
      quantite: 1,
      statut: ArticleSaisieStatut.enAttente,
    ),
    ArticleSaisieItem(
      codeArticle: '30180098',
      taille: 'T-40',
      couleur: 'Rouge',
      stock: 0,
      quantite: 2,
      statut: ArticleSaisieStatut.valide,
    ),
  ];
}
