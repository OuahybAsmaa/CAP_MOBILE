// Module « My Goodays » — satisfaction client du magasin.
//
// Contenu :
// - MyGoodaysPage : tableau de bord (note globale, NPS, répartition des
//   promoteurs, indicateurs de réactivité, courbe d'évolution).
//
// Modèles associés : lib/swapp/models/goodays/
// - GoodaysAvisPage : liste des avis clients (chat My Goodays).
//
// Modèles associés : lib/swapp/models/goodays/
// API              : point de branchement unique dans MyGoodaysPage._loadStats
//                    et GoodaysAvisPage._loadAvis
export 'goodays_avis_page.dart';
export 'my_goodays_page.dart';
