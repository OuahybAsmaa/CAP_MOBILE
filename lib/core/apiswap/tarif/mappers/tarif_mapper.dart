import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';

abstract final class TarifMapper {
  static InfoTarifItem operation(Map<String, dynamic> json) =>
      InfoTarifItem.fromJson(json);

  static InfoTarifArticleItem article(Map<String, dynamic> json) =>
      InfoTarifArticleItem.fromJson(json);
}
