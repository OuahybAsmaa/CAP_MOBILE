import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reception_api_service.dart';

final receptionApiServiceProvider = Provider<ReceptionApiService>(
  (ref) => ReceptionApiService(),
);
