import 'package:cap_mobile/swapp/models/goodays/goodays_avis.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_stats.dart';

abstract final class GoodaysMapper {
  static GoodaysStats stats(GoodaysStats value) => value;
  static List<GoodaysAvis> avis(Iterable<GoodaysAvis> values) =>
      List<GoodaysAvis>.unmodifiable(values);
}
