import 'package:flutter/services.dart';

class DataWedgeService {
  static const _channel =
  EventChannel('com.example.cap_mobile1/scan_events');

  static Stream<String> get scanStream => _channel
      .receiveBroadcastStream()
      .map((event) => event.toString().trim())
      .where((s) => s.isNotEmpty);
}