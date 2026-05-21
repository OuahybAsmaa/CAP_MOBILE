import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataWedgeServiceProvider = Provider<DataWedgeService>((ref) {
  return DataWedgeService();
});

class DataWedgeService {
  static final DataWedgeService _instance = DataWedgeService._internal();
  factory DataWedgeService() => _instance;
  DataWedgeService._internal();

  final FlutterDataWedge _dataWedge = FlutterDataWedge();
  StreamSubscription<ScanResult>? _internalSubscription;
  final StreamController<String> _scanController =
  StreamController<String>.broadcast();

  bool _initialized = false;

  Stream<String> get onScan => _scanController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _dataWedge.initialize();
      _internalSubscription = _dataWedge.onScanResult.listen((result) {
        _scanController.add(result.data);
      });
      _initialized = true;
      debugPrint('DataWedgeService initialisé');
    } catch (e) {
      debugPrint('DataWedgeService erreur: $e');
    }
  }
}