// =============================================================================
// CapMobile — Module Swapp — Données mock « Ranger / système de jeton »
// -----------------------------------------------------------------------------
// Fonctionnalité : Jeu de test en attendant l’intégration API ranger + jetons.
// Design         : Valeurs statiques pour jetons et adresses mock.
// UI             : Alimente RangerPanel (libellé jeton, adresses, compteur).
// Spécifications : Remplacer par service API quand endpoint disponible.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Données de démonstration pour l’écran « Ranger à l’adresse ».
class RangerMockData {
  RangerMockData._();

  static const String tokenSystemLabel = 'système de jeton';

  /// Adresses magasin fictives pour saisie / micro mock.
  static const List<String> sampleAddresses = [
    'A-12-03',
    'B-04-15',
    'C-08-22',
    'RESERVE-01',
    'RAYON-CASUAL-07',
  ];

  static const int initialTokenCount = 3;

  /// Libellés mock affichés sur chaque chip jeton (mode test).
  static const List<String> tokenChipLabels = [
    'Pick magasin',
    'Stock rayon',
    'Réserve',
  ];

  static String tokenLabelAt(int index) {
    if (index >= 0 && index < tokenChipLabels.length) {
      return tokenChipLabels[index];
    }
    return 'Jeton ${index + 1}';
  }

  /// Adresse suggérée par défaut (mock).
  static String defaultSuggestedAddress() => sampleAddresses.first;

  /// Simule une reconnaissance vocale — adresse aléatoire mock.
  static String mockVoiceAddress() {
    final index = DateTime.now().millisecond % sampleAddresses.length;
    return sampleAddresses[index];
  }

  /// Simule la validation ranger côté serveur (mock).
  static Future<RangerSubmitResult> submitMock({
    required String address,
    required int tokensBefore,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return const RangerSubmitResult(
        success: false,
        message: 'Veuillez saisir une adresse de rangement.',
      );
    }
    if (tokensBefore <= 0) {
      return const RangerSubmitResult(
        success: false,
        message: 'Plus de jetons disponibles (mode test).',
      );
    }
    return RangerSubmitResult(
      success: true,
      message: 'Article rangé à $trimmed · jeton consommé (test)',
      remainingTokens: tokensBefore - 1,
    );
  }
}

/// Résultat mock après action « Ranger ».
class RangerSubmitResult {
  final bool success;
  final String message;
  final int? remainingTokens;

  const RangerSubmitResult({
    required this.success,
    required this.message,
    this.remainingTokens,
  });
}
