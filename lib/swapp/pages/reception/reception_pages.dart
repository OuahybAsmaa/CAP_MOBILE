// Module « Réception » — accueil des marchandises en magasin.
//
// Parcours :
//   ReceptionsMenuPage (hub)
//     ├── CollectionReceptionPage  : liste des BL à réceptionner
//     │     └── SupportsBlPage     : supports / colis d'un BL (double-clic)
//     ├── ReceptionReassortPage    : scan des colis de réassort
//     └── ColisNonValidesPage      : colis en attente de validation
//
// Modèles associés : lib/swapp/models/bl_collection_item.dart,
//   support_collection_item.dart, colis_reassort_item.dart,
//   colis_non_valide_item.dart
export 'colis_non_valides_page.dart';
export 'collection_reception_page.dart';
export 'reception_reassort_page.dart';
export 'receptions_menu_page.dart';
export 'supports_bl_page.dart';
