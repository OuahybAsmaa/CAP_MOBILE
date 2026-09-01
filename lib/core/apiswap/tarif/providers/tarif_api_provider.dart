import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tarif_api_service.dart';

final tarifApiServiceProvider = Provider<TarifApiService>(
  (ref) => TarifApiService(),
);
