import 'package:cap_mobile/swapp/models/goodays/goodays_avis.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_periode.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_stats.dart';

import '../data/goodays_avis_test_data.dart';
import '../data/goodays_test_data.dart';
import '../mappers/goodays_mapper.dart';

class GoodaysApiService {
  Future<GoodaysStats> fetchStats(GoodaysPeriode periode) async =>
      GoodaysMapper.stats(GoodaysDemoData.forPeriode(periode));

  Future<List<GoodaysAvis>> fetchAvis() async =>
      GoodaysMapper.avis(GoodaysAvisDemoData.all());
}
