import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/inventory_service.dart';

// ──────────────────────────────────────────────────────────────
//  TYPE DE CONTRÔLE
// ──────────────────────────────────────────────────────────────
enum ControlMode {
  findUnknownTags,
  findEncodedTags,
  findAll,
}

extension ControlModeLabel on ControlMode {
  String get label {
    switch (this) {
      case ControlMode.findUnknownTags:
        return 'Puces vierges (Non encodées)';
      case ControlMode.findEncodedTags:
        return 'Puces encodées';
      case ControlMode.findAll:
        return 'Toutes les puces';
    }
  }

  String get description {
    switch (this) {
      case ControlMode.findUnknownTags:
        return 'Détecte les puces avec EPC usine (3034...) — mal encodées';
      case ControlMode.findEncodedTags:
        return 'Détecte les puces correctement encodées (3039...)';
      case ControlMode.findAll:
        return 'Affiche toutes les puces détectées sans filtre';
    }
  }

  String get iconDescription {
    switch (this) {
      case ControlMode.findUnknownTags:
        return '⚠️';
      case ControlMode.findEncodedTags:
        return '✅';
      case ControlMode.findAll:
        return '📋';
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  MODÈLE TAG CONTRÔLE
// ──────────────────────────────────────────────────────────────
class ControlTag {
  final String epc;
  final double rssi;
  final int count;
  final bool isVirgin;
  final DateTime firstSeen;
  final DateTime lastSeen;

  const ControlTag({
    required this.epc,
    required this.rssi,
    required this.count,
    required this.isVirgin,
    required this.firstSeen,
    required this.lastSeen,
  });

  static bool checkIsVirgin(String epc) =>
      epc.toUpperCase().startsWith('3034');

  ControlTag copyWithNewRead(double newRssi) {
    return ControlTag(
      epc:       epc,
      rssi:      newRssi,
      count:     count + 1,
      isVirgin:  isVirgin,
      firstSeen: firstSeen,
      lastSeen:  DateTime.now(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  STATE  — plus de gestion lecteur ici
// ──────────────────────────────────────────────────────────────
class ControlState {
  final ControlMode selectedMode;
  final bool isRunning;
  final List<ControlTag> allTags;
  final List<ControlTag> filteredTags;
  final int totalReads;
  final double readRate;
  final Duration readTime;
  final String? error;

  const ControlState({
    this.selectedMode = ControlMode.findUnknownTags,
    this.isRunning    = false,
    this.allTags      = const [],
    this.filteredTags = const [],
    this.totalReads   = 0,
    this.readRate     = 0.0,
    this.readTime     = Duration.zero,
    this.error,
  });

  int get virginCount  => allTags.where((t) => t.isVirgin).length;
  int get encodedCount => allTags.where((t) => !t.isVirgin).length;
  int get uniqueCount  => allTags.length;

  ControlState copyWith({
    ControlMode? selectedMode,
    bool? isRunning,
    List<ControlTag>? allTags,
    List<ControlTag>? filteredTags,
    int? totalReads,
    double? readRate,
    Duration? readTime,
    String? error,
    bool clearError = false,
  }) {
    return ControlState(
      selectedMode:  selectedMode  ?? this.selectedMode,
      isRunning:     isRunning     ?? this.isRunning,
      allTags:       allTags       ?? this.allTags,
      filteredTags:  filteredTags  ?? this.filteredTags,
      totalReads:    totalReads    ?? this.totalReads,
      readRate:      readRate      ?? this.readRate,
      readTime:      readTime      ?? this.readTime,
      error:         clearError    ? null : error ?? this.error,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  NOTIFIER — reçoit le nom du reader connecté en paramètre
// ──────────────────────────────────────────────────────────────
class ControlNotifier extends StateNotifier<ControlState> {
  final InventoryService _service;

  StreamSubscription? _tagSubscription;
  Timer? _timerTick;
  DateTime? _startTime;
  int _readsInLastSecond = 0;

  ControlNotifier(this._service) : super(const ControlState());

  // ── Changer le mode ──
  void setMode(ControlMode mode) {
    if (state.isRunning) return;
    state = state.copyWith(
      selectedMode: mode,
      filteredTags: _applyFilter(state.allTags, mode),
    );
  }

  List<ControlTag> _applyFilter(List<ControlTag> tags, ControlMode mode) {
    switch (mode) {
      case ControlMode.findUnknownTags:
        return tags.where((t) => t.isVirgin).toList();
      case ControlMode.findEncodedTags:
        return tags.where((t) => !t.isVirgin).toList();
      case ControlMode.findAll:
        return List.from(tags);
    }
  }

  // ── Démarrer — reçoit le nom du lecteur depuis rfidProvider ──
  Future<void> startControl(String readerName) async {
    if (state.isRunning) return;

    _stopInternals();

    state = state.copyWith(
      isRunning:    true,
      allTags:      [],
      filteredTags: [],
      totalReads:   0,
      readRate:     0.0,
      readTime:     Duration.zero,
      clearError:   true,
    );

    _tagSubscription = _service.tagStream.listen(
          (event) {
        if (!state.isRunning) return;
        if (event is Map) {
          if (event['event'] == 'tag') {
            _onTagReceived(
              tagId: event['tagId'] as String,
              rssi:  (event['rssi'] as num).toDouble(),
            );
          } else if (event['event'] == 'disconnected') {
            _onDisconnected();
          }
        }
      },
      onError: (e) {
        state = state.copyWith(error: 'Erreur stream: $e', isRunning: false);
      },
    );

    try {
      await _service.startInventory();
    } catch (e) {
      _stopInternals();
      state = state.copyWith(isRunning: false, error: 'Erreur démarrage: $e');
      return;
    }

    _startTime         = DateTime.now();
    _readsInLastSecond = 0;
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());
  }

  // ── Arrêter ──
  Future<void> stopControl() async {
    if (!state.isRunning) return;
    state = state.copyWith(isRunning: false);
    _stopInternals();
    try { await _service.stopInventory(); } catch (_) {}
  }

  // ── Reset ──
  void reset() {
    _stopInternals();
    state = ControlState(selectedMode: state.selectedMode);
  }

  void _onTagReceived({required String tagId, required double rssi}) {
    if (!state.isRunning) return;
    final currentTags = List<ControlTag>.from(state.allTags);
    final index = currentTags.indexWhere((t) => t.epc == tagId);

    if (index == -1) {
      currentTags.add(ControlTag(
        epc:       tagId,
        rssi:      rssi,
        count:     1,
        isVirgin:  ControlTag.checkIsVirgin(tagId),
        firstSeen: DateTime.now(),
        lastSeen:  DateTime.now(),
      ));
    } else {
      currentTags[index] = currentTags[index].copyWithNewRead(rssi);
    }

    _readsInLastSecond++;
    state = state.copyWith(
      allTags:      currentTags,
      filteredTags: _applyFilter(currentTags, state.selectedMode),
      totalReads:   state.totalReads + 1,
    );
  }

  void _onTimerTick() {
    if (!state.isRunning) return;
    state = state.copyWith(
      readTime: DateTime.now().difference(_startTime!),
      readRate: _readsInLastSecond.toDouble(),
    );
    _readsInLastSecond = 0;
  }

  void _onDisconnected() {
    _stopInternals();
    state = state.copyWith(isRunning: false, error: 'Lecteur déconnecté');
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
//  PROVIDER
// ──────────────────────────────────────────────────────────────
final controlServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

final controlProvider =
StateNotifierProvider<ControlNotifier, ControlState>((ref) {
  final service = ref.watch(controlServiceProvider);
  return ControlNotifier(service);
});