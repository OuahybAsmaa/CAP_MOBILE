import 'package:flutter/material.dart';

/// Palette de couleurs de l'application CapMobile
/// Thème: Bleu professionnel + Gris bleu
class AppColors {
  // Couleurs principales
  static const Color primary     = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color secondary = Color(0xFF475569); // Gris bleu foncé
  static const Color tertiary = Color(0xFF0EA5E9); // Bleu ciel (accent)
  static const Color bg          = Color(0xFFF0F2FF);
  static const Color primarySoft = Color(0xFFE8EAF6);
  static const Color textMuted   = Color(0xFF9CA3AF);

  // Couleurs neutres
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Couleurs de statut
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF1E40AF);

  // Couleurs neutrales
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Couleurs spécialisées
  static const Color orange = Color(0xFFEA580C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
  );
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
  );
}
