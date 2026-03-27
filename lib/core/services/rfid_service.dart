import 'package:flutter/services.dart';

class RfidService {
  static const _methodChannel =
  MethodChannel('com.example.cap_mobile1/rfid');
  static const _eventChannel =
  EventChannel('com.example.cap_mobile1/rfid_events');

  Function()? onScanButtonPressed;

  RfidService() {
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScanButton') {
        onScanButtonPressed?.call();
      }
    });
  }

  Future<List<Map<String, String>>> getAvailableReaders() async {
    final List result =
    await _methodChannel.invokeMethod('getAvailableReaders');
    return result.map((e) => Map<String, String>.from(e)).toList();
  }

  Future<String> connect(String readerName) async {
    return await _methodChannel
        .invokeMethod('connect', {'readerName': readerName});
  }

  Future<String> disconnect() async {
    return await _methodChannel.invokeMethod('disconnect');
  }

  Future<String> readSingleTag() async {
    return await _methodChannel.invokeMethod('readSingleTag');
  }

  Future<String> writeTag(String tagId, String data) async {
    return await _methodChannel.invokeMethod('writeTag', {
      'tagId': tagId,
      'data':  data,
    });
  }

  Stream<dynamic> get tagStream =>
      _eventChannel.receiveBroadcastStream();
}