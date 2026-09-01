import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ranger_api_service.dart';

final rangerApiServiceProvider = Provider<RangerApiService>(
  (ref) => RangerApiService(),
);
