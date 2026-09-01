// Module « Produit » — consultation d'un article et de ses stocks.
//
// Parcours :
//   SwappInfosProduitMenuPage (hub)
//     ├── DetailProduitPage    : fiche produit (stocks, avis, actions)
//     │     └── ReserveProduitPage : déclaration d'une réserve
//     ├── DetailProduitPage2   : variante de la fiche produit
//     └── InfoOtPage           : ordres de transfert liés au produit
//
// Modèles associés : lib/swapp/models/product_stock_view.dart,
//   stock_column.dart, info_ot_item.dart, reserve_mock_data.dart
export 'detail_produit_page.dart';
export 'produit_scan_page.dart';
export 'detail_produit_page2.dart';
export 'info_ot_page.dart';
export 'reserve_produit_page.dart';
export 'swapp_infos_produit_menu_page.dart';
