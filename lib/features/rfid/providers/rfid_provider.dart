import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/rfid_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/rfid_reader_model.dart';

// ---- État ----
class RfidState {
  final List<RfidReaderModel> availableReaders;
  final RfidReaderModel? connectedReader;
  final bool isLoading;
  final String? error;
  final String? message;
  final String? lastScannedTag;

  RfidState({
    this.availableReaders = const [],
    this.connectedReader,
    this.isLoading = false,
    this.error,
    this.message,
    this.lastScannedTag,
  });

  RfidState copyWith({
    List<RfidReaderModel>? availableReaders,
    RfidReaderModel? connectedReader,
    bool? isLoading,
    String? error,
    String? message,
    String? lastScannedTag,
    bool clearConnected  = false,
    bool clearError      = false,
    bool clearMessage    = false,
    bool clearScannedTag = false,
  }) {
    return RfidState(
      availableReaders: availableReaders ?? this.availableReaders,
      connectedReader:  clearConnected   ? null : connectedReader ?? this.connectedReader,
      isLoading:        isLoading        ?? this.isLoading,
      error:            clearError       ? null : error           ?? this.error,
      message:          clearMessage     ? null : message         ?? this.message,
      lastScannedTag:   clearScannedTag  ? null : lastScannedTag  ?? this.lastScannedTag,
    );
  }
}

// ---- Notifier ----
class RfidNotifier extends StateNotifier<RfidState> {
  final RfidService _rfidService;
  bool _isConnecting = false;
  StreamSubscription? _eventSubscription;

  RfidNotifier(this._rfidService) : super(RfidState()) {

  }

  Future<void> loadAvailableReaders() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final readers = await _rfidService.getAvailableReaders();
      final models  = readers
          .map((r) => RfidReaderModel.fromMap(r))
          .toList();
      state = state.copyWith(
        availableReaders: models,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error:     'Erreur: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> connectToReader(RfidReaderModel reader) async {
    if (_isConnecting) return;
    _isConnecting = true;
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearMessage: true,
      );
      final msg = await _rfidService.connect(reader.name);

      // Écouter les événements après connexion
      _startListeningEvents();

      state = state.copyWith(
        connectedReader: reader,
        isLoading:       false,
        message:         msg,
      );
    } catch (e) {
      state = state.copyWith(
        error:     'Connexion échouée: ${e.toString()}',
        isLoading: false,
      );
    } finally {
      _isConnecting = false;
    }
  }

  void _startListeningEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _rfidService.tagStream.listen((event) {
      if (event is Map) {
        // Déconnexion physique du lecteur
        if (event['event'] == 'disconnected') {
          state = state.copyWith(
            clearConnected:  true,
            clearScannedTag: true,
            error: 'Lecteur déconnecté',
          );
          _eventSubscription?.cancel();
        }
      }
    });
  }

  Future<void> disconnectReader() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      _eventSubscription?.cancel();
      final msg = await _rfidService.disconnect();
      state = state.copyWith(
        isLoading:       false,
        message:         msg,
        clearConnected:  true,
        clearScannedTag: true,
      );
    } catch (e) {
      state = state.copyWith(
        error:     'Déconnexion échouée: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> readSingleTag() async {
    try {
      state = state.copyWith(clearScannedTag: true, clearError: true);
      final epc = await _rfidService.readSingleTag();
      state = state.copyWith(lastScannedTag: epc);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lecture tag: ${e.toString()}',
      );
    }
  }

  Future<void> writeTag({
    required String tagId,
    required String data,
  }) async {
    await _rfidService.writeTag(tagId, data);
  }

  // NOUVEAU — reset du tag scanné
  void clearScannedTag() {
    state = state.copyWith(clearScannedTag: true);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// ---- Providers ----
final rfidServiceProvider = Provider<RfidService>((ref) {
  // Dépend de authProvider → se recrée à chaque changement d'auth
  ref.watch(authProvider.select((s) => s.isAuthenticated));
  final service = RfidService();
  service.reinitHandler(); // Handler frais à chaque session
  return service;
});

final rfidProvider =
StateNotifierProvider<RfidNotifier, RfidState>((ref) {
  final service = ref.watch(rfidServiceProvider);
  return RfidNotifier(service);
});