// Module « Transfert » — ordres de transfert (OT) et retours dépôt.
//
// Parcours :
//   InfoTransfertMenuPage (hub)
//     ├── OperationsTransfertPage      : OT en attente (popup de reprise)
//     ├── RetourDepotPage              : retours dépôt en attente
//     │     ├── CompteurSelectionPage  : choix du compteur (bouton +)
//     │     ├── ArticlesSaisiePage     : saisie des articles
//     │     └── InfoTransfertDetailPage: détail d'un transfert (double-clic)
//     ├── InfoTransfertDestinationPage : saisie de la destination
//     └── RemiseTransporteurPage       : remise au transporteur
//
// Modèles associés : lib/swapp/models/operation_transfert_item.dart,
//   retour_depot_item.dart, compteur_item.dart, article_saisie_item.dart,
//   info_transfert_item.dart
export 'articles_saisie_page.dart';
export 'compteur_selection_page.dart';
export 'info_transfert_destination_page.dart';
export 'info_transfert_detail_page.dart';
export 'info_transfert_menu_page.dart';
export 'operations_transfert_page.dart';
export 'remise_transporteur_page.dart';
export 'retour_depot_page.dart';
