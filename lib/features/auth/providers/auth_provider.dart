import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../rfid/providers/rfid_provider.dart';
import '../models/collaborateur_model.dart';
//import '../../../core/services/auth_service_mock.dart';

// ─── État ────────────────────────────────────────────────────────────────────

class AuthState {
  final CollaborateurModel? collaborateur;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.collaborateur,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => collaborateur != null;

  AuthState copyWith({
    CollaborateurModel? collaborateur,
    bool? isLoading,
    String? error,
    bool clearError        = false,
    bool clearCollaborateur = false,
  }) {
    return AuthState(
      collaborateur: clearCollaborateur ? null : collaborateur ?? this.collaborateur,
      isLoading:     isLoading ?? this.isLoading,
      error:         clearError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  //les choses à modifier
 final AuthService _authService;
 final Ref _ref;
  //final dynamic _authService;

 AuthNotifier(this._authService, this._ref) : super(const AuthState());

  /// Appelé quand DataWedge envoie le code scanné
  Future<void> authenticate(String codeCollab) async {
    final code = codeCollab.trim();
    if (code.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final collab = await _authService.getCollaborateur(code);
      state = state.copyWith(
        collaborateur: collab,
        isLoading:     false,
      );
    } catch (e) {
      state = state.copyWith(
        error:     e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  String getPhotoUrl(int codeCollab) =>
      _authService.getPhotoUrl(codeCollab);

 void logout() {
   // On capture ref avant de lire le notifier
   // Déconnecter le lecteur RFID proprement
   try {
     _ref.read(rfidProvider.notifier).disconnectReader();
   } catch (_) {}
   state = const AuthState();
 }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

//les choses a changer
/*const bool USE_MOCK = true; // Ajoute cette constante avant

final authServiceProvider = Provider<dynamic>((ref) {
  if (USE_MOCK) {
    return AuthServiceMock();
  } else {
    return AuthService();
  }
});*/

//stop ici


final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service, ref); // ← passer ref
});