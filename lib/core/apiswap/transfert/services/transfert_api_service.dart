import 'package:cap_mobile/swapp/models/article_saisie_item.dart';
import 'package:cap_mobile/swapp/models/compteur_item.dart';
import 'package:cap_mobile/swapp/models/info_ot_item.dart';
import 'package:cap_mobile/swapp/models/info_transfert_item.dart';
import 'package:cap_mobile/swapp/models/operation_transfert_item.dart';
import 'package:cap_mobile/swapp/models/retour_depot_item.dart';

import '../data/article_saisie_test_data.dart';
import '../data/compteur_test_data.dart';
import '../data/info_ot_test_data.dart';
import '../data/info_transfert_test_data.dart';
import '../data/operation_transfert_test_data.dart';
import '../data/retour_depot_test_data.dart';

class TransfertApiService {
  Future<List<InfoOtItem>> fetchOts({int? codeMag}) async =>
      InfoOtDemoData.items();

  Future<InfoTransfertFiche> fetchFiche(
    int codeMagDest, {
    String? nomMagDest,
  }) async => InfoTransfertDemoData.fichePour(codeMagDest, nomMag: nomMagDest);

  Future<List<OperationTransfertItem>> fetchOperations() async =>
      OperationTransfertDemoData.items();

  Future<List<RetourDepotItem>> fetchRetoursDepot() async =>
      RetourDepotDemoData.items();

  Future<List<ArticleSaisieItem>> fetchArticlesSaisie() async =>
      ArticleSaisieDemoData.items();

  Future<List<CompteurItem>> fetchCompteurs() async => CompteurDemoData.items();
}
