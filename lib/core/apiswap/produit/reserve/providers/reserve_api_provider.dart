import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reserve_api_service.dart';

final reserveApiServiceProvider = Provider<ReserveApiService>(
  (ref) => ReserveApiService(),
);
