import 'package:cap_mobile/swapp/models/bl_collection_item.dart';
import 'package:cap_mobile/swapp/models/colis_non_valide_item.dart';
import 'package:cap_mobile/swapp/models/colis_reassort_item.dart';
import 'package:cap_mobile/swapp/models/support_collection_item.dart';

import '../data/bl_collection_test_data.dart';
import '../data/colis_non_valide_test_data.dart';
import '../data/colis_reassort_test_data.dart';
import '../data/support_collection_test_data.dart';

class ReceptionApiService {
  Future<List<BlCollectionItem>> fetchCollections() async =>
      BlCollectionDemoData.items();

  Future<List<ColisNonValideItem>> fetchColisNonValides() async =>
      ColisNonValideDemoData.items();

  Future<List<ColisReassortItem>> fetchReassort() async =>
      ColisReassortDemoData.file();

  Future<List<SupportCollectionItem>> fetchSupports(
    BlCollectionItem bl,
  ) async => SupportCollectionDemoData.forBl(bl);
}
