import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/inventory_service.dart';
import '../models/tag_model.dart';

// ──────────────────────────────────────────────────────────────
//  Provider du service
// ──────────────────────────────────────────────────────────────
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

// ──────────────────────────────────────────────────────────────
//  State
// ──────────────────────────────────────────────────────────────
class InventoryState {
  final bool isRunning;
  final int totalReads;
  final int uniqueTags;
  final double readRate;
  final Duration readTime;
  final int batteryLevel;
  final List<TagModel> tags;
  final String? error;

  // NOUVEAU
  final List<String> availableReaders;
  final String? connectedReader;
  final bool isConnecting;

  const InventoryState({
    this.isRunning       = false,
    this.totalReads      = 0,
    this.uniqueTags      = 0,
    this.readRate        = 0.0,
    this.readTime        = Duration.zero,
    this.batteryLevel    = -1,
    this.tags            = const [],
    this.error,
    this.availableReaders = const [],
    this.connectedReader,
    this.isConnecting    = false,
  });

  InventoryState copyWith({
    bool? isRunning,
    int? totalReads,
    int? uniqueTags,
    double? readRate,
    Duration? readTime,
    int? batteryLevel,
    List<TagModel>? tags,
    String? error,
    bool clearError        = false,
    List<String>? availableReaders,
    String? connectedReader,
    bool clearConnected    = false,
    bool? isConnecting,
  }) {
    return InventoryState(
      isRunning:        isRunning        ?? this.isRunning,
      totalReads:       totalReads       ?? this.totalReads,
      uniqueTags:       uniqueTags       ?? this.uniqueTags,
      readRate:         readRate         ?? this.readRate,
      readTime:         readTime         ?? this.readTime,
      batteryLevel:     batteryLevel     ?? this.batteryLevel,
      tags:             tags             ?? this.tags,
      error:            clearError       ? null : error ?? this.error,
      availableReaders: availableReaders ?? this.availableReaders,
      connectedReader:  clearConnected   ? null : connectedReader ?? this.connectedReader,
      isConnecting:     isConnecting     ?? this.isConnecting,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Notifier
// ──────────────────────────────────────────────────────────────
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryService _service;

  StreamSubscription? _tagSubscription;
  Timer? _timerTick;
  DateTime? _startTime;
  int _readsInLastSecond = 0;

  InventoryNotifier(this._service) : super(const InventoryState());

  Future<void> loadAvailableReaders() async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);
      final readers = await _service.getAvailableReaders();
      state = state.copyWith(
        availableReaders: readers.map((r) => r['name'] ?? '').toList(),
        isConnecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lecteurs: $e',
        isConnecting: false,
      );
    }
  }

  // NOUVEAU ── Connexion ──
  Future<void> connectToReader(String readerName) async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);
      await _service.connect(readerName);
      state = state.copyWith(
        connectedReader: readerName,
        isConnecting: false,
      );
      // Charger la batterie dès la connexion
      await refreshBattery();
    } catch (e) {
      state = state.copyWith(
        error: 'Connexion échouée: $e',
        isConnecting: false,
      );
    }
  }

  // NOUVEAU ── Déconnexion ──
  Future<void> disconnectReader() async {
    try {
      await _service.disconnect();
      state = state.copyWith(clearConnected: true);
    } catch (e) {
      state = state.copyWith(error: 'Déconnexion échouée: $e');
    }
  }

  // ── Batterie ──
  Future<void> refreshBattery() async {
    try {
      final level = await _service.getBatteryLevel();
      state = state.copyWith(batteryLevel: level);
    } catch (_) {}
  }

  // ── Configurer banque mémoire ──
  Future<void> configureMemoryBank(String memoryBank) async {
    try {
      await _service.configureMemoryBank(memoryBank);
    } catch (_) {}
  }

  // ── Démarrer inventaire ──
  Future<void> startInventory() async {
    if (state.isRunning) return;

    _stopInternals();

    state = state.copyWith(
      isRunning:  true,
      totalReads: 0,
      uniqueTags: 0,
      readRate:   0.0,
      readTime:   Duration.zero,
      tags:       [],
      clearError: true,
    );

    // Écouter le stream AVANT de démarrer le SDK
    _tagSubscription = _service.tagStream.listen(
          (event) {
        if (!state.isRunning) return;
        if (event is Map) {
          if (event['event'] == 'tag') {
            _onTagReceived(
              tagId:          event['tagId'] as String,
              rssi:           (event['rssi'] as num).toDouble(),
              memoryBankData: event['memoryBankData'] as String? ?? '',
              tidData:        event['tidData'] as String? ?? '',
            );
          } else if (event['event'] == 'disconnected') {
            _onDisconnected();
          }
        }
      },
      onError: (e) {
        state = state.copyWith(
          error:     'Erreur stream: $e',
          isRunning: false,
        );
      },
    );

    try {
      await _service.startInventory();
    } catch (e) {
      _stopInternals();
      state = state.copyWith(
        isRunning: false,
        error:     'Erreur démarrage: $e',
      );
      return;
    }

    _startTime         = DateTime.now();
    _readsInLastSecond = 0;
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
    });
  }

  // ── Arrêter inventaire ──
  Future<void> stopInventory() async {
    if (!state.isRunning) return;
    state = state.copyWith(isRunning: false);
    _stopInternals();
    try {
      await _service.stopInventory();
    } catch (_) {}
  }

  // ── Reset ──
  void reset() {
    _stopInternals();
    state = InventoryState(batteryLevel: state.batteryLevel);
  }

  // ── Tag reçu ──
  void _onTagReceived({
    required String tagId,
    required double rssi,
    String memoryBankData = '',
    String tidData = '',
  }) {
    if (!state.isRunning) return;

    final currentTags = List<TagModel>.from(state.tags);
    final index = currentTags.indexWhere((t) => t.epc == tagId);

    if (index == -1) {
      currentTags.add(TagModel(
        epc:            tagId,
        count:          1,
        rssi:           rssi,
        memoryBankData: memoryBankData,
        tidData:        tidData,
      ));
    } else {
      currentTags[index] = currentTags[index].copyWithNewRead(
        rssi,
        memoryBankData: memoryBankData,
        tidData:        tidData,
      );
    }

    _readsInLastSecond++;

    state = state.copyWith(
      tags:       currentTags,
      totalReads: state.totalReads + 1,
      uniqueTags: currentTags.length,
    );
  }

  void _onTimerTick() {
    if (!state.isRunning) return;
    final elapsed = DateTime.now().difference(_startTime!);
    state = state.copyWith(
      readTime: elapsed,
      readRate: _readsInLastSecond.toDouble(),
    );
    _readsInLastSecond = 0;
  }

  void _onDisconnected() {
    _stopInternals();
    state = state.copyWith(
      isRunning: false,
      error:     'Lecteur déconnecté',
    );
  }

  void _stopInternals() {
    _timerTick?.cancel();
    _timerTick = null;
    _tagSubscription?.cancel();
    _tagSubscription = null;
    _readsInLastSecond = 0;
  }

  @override
  void dispose() {
    _stopInternals();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────────────
//  Provider principal
// ──────────────────────────────────────────────────────────────
final inventoryProvider =
StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  return InventoryNotifier(service);
});