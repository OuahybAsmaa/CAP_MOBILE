import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/transfert_api_service.dart';

final transfertApiServiceProvider = Provider<TransfertApiService>(
  (ref) => TransfertApiService(),
);
