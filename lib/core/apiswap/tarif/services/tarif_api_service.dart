import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';

import '../data/info_tarif_article_test_data.dart';
import '../data/info_tarif_test_data.dart';

class TarifApiService {
  Future<List<InfoTarifItem>> fetchOperations({int? codeMag}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return InfoTarifDemoData.operations();
  }

  Future<List<InfoTarifArticleItem>> fetchArticles(
    List<InfoTarifItem> operations,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return InfoTarifArticleDemoData.articlesForOperations(
      operations.map((operation) => operation.code),
    );
  }
}
