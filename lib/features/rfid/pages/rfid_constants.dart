import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS — partagés entre toutes les pages RFID
// ──────────────────────────────────────────────────────────────
class AppColors {
  static const bg          = Color(0xFFDCF4F8);
  static const surface     = Color(0xFFFFFFFF);
  static const primary     = Color(0xFF0070F3);
  static const primaryDark = Color(0xFF1E40AF);
  static const primarySoft = Color(0xFFEBF5FF);
  static const success     = Color(0xFF10B981);
  static const warning     = Color(0xFFF59E0B);
  static const error       = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFD1D5DB);
}

// ──────────────────────────────────────────────────────────────
//  MODÈLE MODE RFID — partagé entre RfidPage et RfidEncodingPage
// ──────────────────────────────────────────────────────────────
class RfidMode {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool available;

  const RfidMode({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.available = false,
  });
}

// ──────────────────────────────────────────────────────────────
//  LISTE DES MODES DISPONIBLES
// ──────────────────────────────────────────────────────────────
const rfidModes = [
  RfidMode(
    id: 'encoding',
    label: 'Encodage étiquette',
    subtitle: 'Écriture EPC dans une puce vierge',
    icon: Icons.nfc_rounded,
    color: AppColors.primary,
    available: true,
  ),
  RfidMode(
    id: 'inventory',
    label: 'Inventaire',
    subtitle: 'Lecture & comptage des puces',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF059669),
    available: false,
  ),
  RfidMode(
    id: 'location',
    label: 'Localisation RSSI',
    subtitle: 'Recherche article par signal',
    icon: Icons.my_location_rounded,
    color: Color(0xFF7C3AED),
    available: false,
  ),
  RfidMode(
    id: 'audit',
    label: 'Audit stock',
    subtitle: 'Vérification & rapprochement',
    icon: Icons.fact_check_rounded,
    color: Color(0xFFD97706),
    available: false,
  ),
];