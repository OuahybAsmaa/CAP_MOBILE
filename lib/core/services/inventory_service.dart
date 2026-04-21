import 'dart:async';
import 'package:flutter/services.dart';

class InventoryService {
  static const _methodChannel =
  MethodChannel('com.example.cap_mobile1/rfid');
  static const _eventChannel =
  EventChannel('com.example.cap_mobile1/rfid_events');

  Stream<dynamic> get tagStream => _eventChannel.receiveBroadcastStream();

  // ── Lecteurs disponibles ──
  Future<List<Map<String, String>>> getAvailableReaders() async {
    try {
      final List result =
      await _methodChannel.invokeMethod('getAvailableReaders');
      return result.map((e) => Map<String, String>.from(e)).toList();
    } on PlatformException catch (e) {
      throw Exception('getAvailableReaders error: ${e.message}');
    }
  }

  // ── Connexion ──
  Future<String> connect(String readerName) async {
    try {
      return await _methodChannel
          .invokeMethod('connect', {'readerName': readerName});
    } on PlatformException catch (e) {
      throw Exception('connect error: ${e.message}');
    }
  }

  // ── Déconnexion ──
  Future<String> disconnect() async {
    try {
      return await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw Exception('disconnect error: ${e.message}');
    }
  }

  // ── Niveau de batterie ──
  Future<int> getBatteryLevel() async {
    try {
      final int level =
      await _methodChannel.invokeMethod('getBatteryLevel');
      return level;
    } on PlatformException catch (e) {
      throw Exception('getBatteryLevel error: ${e.message}');
    }
  }

  // ── Démarrer l'inventaire ──
  Future<String> startInventory() async {
    try {
      return await _methodChannel.invokeMethod('startInventory');
    } on PlatformException catch (e) {
      throw Exception('startInventory error: ${e.message}');
    }
  }

  // ── Arrêter l'inventaire ──
  Future<String> stopInventory() async {
    try {
      return await _methodChannel.invokeMethod('stopInventory');
    } on PlatformException catch (e) {
      throw Exception('stopInventory error: ${e.message}');
    }
  }

  // ── Configurer la banque mémoire ──
  Future<String> configureMemoryBank(String memoryBank) async {
    try {
      return await _methodChannel.invokeMethod(
        'configureMemoryBank',
        {'memoryBank': memoryBank},
      );
    } on PlatformException catch (e) {
      throw Exception('configureMemoryBank error: ${e.message}');
    }
  }
}