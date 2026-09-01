import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/goodays_api_service.dart';

final goodaysApiServiceProvider = Provider<GoodaysApiService>(
  (ref) => GoodaysApiService(),
);
