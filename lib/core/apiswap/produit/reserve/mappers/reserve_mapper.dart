import 'package:cap_mobile/swapp/models/reserve_sku_item.dart';

abstract final class ReserveMapper {
  static List<ReserveSkuItem> items(Iterable<ReserveSkuItem> values) =>
      List<ReserveSkuItem>.unmodifiable(values);
}
