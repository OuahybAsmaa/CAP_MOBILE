import 'package:flutter/services.dart';

class ConnectionService {
  static const _methodChannel =
  MethodChannel('com.example.cap_mobile1/rfid');
  static const _eventChannel =
  EventChannel('com.example.cap_mobile1/rfid_events');

  // ── Lecteurs disponibles ──
  Future<List<String>> getAvailableReaders() async {
    try {
      final List result =
      await _methodChannel.invokeMethod('getAvailableReaders');
      return result
          .map((e) => (Map<String, String>.from(e))['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      throw Exception('getAvailableReaders error: ${e.message}');
    }
  }

  // ── Connexion ──
  Future<void> connect(String readerName) async {
    try {
      await _methodChannel
          .invokeMethod('connect', {'readerName': readerName});
    } on PlatformException catch (e) {
      throw Exception('connect error: ${e.message}');
    }
  }

  // ── Déconnexion ──
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw Exception('disconnect error: ${e.message}');
    }
  }

  // ── Écouter les événements (déconnexion physique) ──
  Stream<dynamic> get eventStream =>
      _eventChannel.receiveBroadcastStream();
}