import 'package:cap_mobile/swapp/models/reserve_sku_item.dart';

import '../data/reserve_test_data.dart';
import '../mappers/reserve_mapper.dart';

class ReserveApiService {
  Future<List<ReserveSkuItem>> fetchItems({int? codeMag}) async =>
      ReserveMapper.items(ReserveMockData.sampleItems);
}
