import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connection_service.dart';

// ──────────────────────────────────────────────────────────────
//  Service Provider
// ──────────────────────────────────────────────────────────────
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return ConnectionService();
});

// ──────────────────────────────────────────────────────────────
//  State
// ──────────────────────────────────────────────────────────────
class ConnectionState {
  final List<String> availableReaders;
  final String? connectedReader;
  final bool isConnecting;
  final String? error;

  const ConnectionState({
    this.availableReaders = const [],
    this.connectedReader,
    this.isConnecting = false,
    this.error,
  });

  bool get isConnected => connectedReader != null;

  ConnectionState copyWith({
    List<String>? availableReaders,
    String? connectedReader,
    bool clearConnected = false,
    bool? isConnecting,
    String? error,
    bool clearError = false,
  }) {
    return ConnectionState(
      availableReaders: availableReaders ?? this.availableReaders,
      connectedReader:  clearConnected
          ? null
          : connectedReader ?? this.connectedReader,
      isConnecting:     isConnecting ?? this.isConnecting,
      error:            clearError ? null : error ?? this.error,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Notifier (ViewModel)
// ──────────────────────────────────────────────────────────────
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final ConnectionService _service;

  ConnectionNotifier(this._service) : super(const ConnectionState()) {
    _listenPhysicalDisconnect();
  }

  // Écouter la déconnexion physique du lecteur
  void _listenPhysicalDisconnect() {
    _service.eventStream.listen((event) {
      if (event is Map && event['event'] == 'disconnected') {
        state = state.copyWith(clearConnected: true);
      }
    });
  }

  Future<void> loadAvailableReaders() async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);
      final readers = await _service.getAvailableReaders();
      state = state.copyWith(
        availableReaders: readers,
        isConnecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lecteurs: $e',
        isConnecting: false,
      );
    }
  }

  Future<void> connectToReader(String readerName) async {
    if (state.connectedReader == readerName) return; // déjà connecté
    try {
      state = state.copyWith(isConnecting: true, clearError: true);
      if (state.connectedReader != null) {
        await _service.disconnect(); // déconnecter l'ancien
      }
      await _service.connect(readerName);
      state = state.copyWith(
        connectedReader: readerName,
        isConnecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Connexion échouée: $e',
        isConnecting: false,
        clearConnected: true,
      );
    }
  }

  Future<void> disconnectReader() async {
    try {
      await _service.disconnect();
      state = state.copyWith(clearConnected: true);
    } catch (e) {
      state = state.copyWith(error: 'Déconnexion échouée: $e');
    }
  }
  void onPhysicalDisconnect() {
    state = state.copyWith(clearConnected: true);
  }
}

// ──────────────────────────────────────────────────────────────
//  Provider global
// ──────────────────────────────────────────────────────────────
final connectionProvider =
StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final service = ref.watch(connectionServiceProvider);
  return ConnectionNotifier(service);
});