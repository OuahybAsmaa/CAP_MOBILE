// =============================================================================
// CapMobile — Module Swapp — Widgets formulaire client (partagés)
// -----------------------------------------------------------------------------
// Fonctionnalité : Composants UI réutilisés par ClientSearchPage et ClientAddPage.
// Design         : Header dégradé bleu ; champs capsule blancs bordure primary ;
//                  micro circulaire ; toggle pill 10/50 clients.
// UI             : ClientPageScaffold = Column [header | body] ;
//                  ClientFormField = TextField avec icône circulaire colorée ;
//                  ClientMicButton / ClientPageSizeSelector = bas formulaire recherche.
// Spécifications : Couleurs AppColors ; actions header configurables (stats, +, search).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Scaffold client — header bleu + corps (recherche ou ajout)
// UI     : AppBar custom avec retour, titre, sous-titre optionnel, actions droite.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class ClientPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onAdd;
  final VoidCallback? onStats;
  final bool showAddAction;
  final bool showStatsAction;
  final IconData searchIcon;
  final String searchTooltip;
  final Widget body;

  const ClientPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.onSearch,
    this.onAdd,
    this.onStats,
    this.showAddAction = true,
    this.showStatsAction = true,
    this.searchIcon = Icons.search_rounded,
    this.searchTooltip = 'Rechercher',
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(4, top + 4, 4, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showStatsAction)
                  IconButton(
                    onPressed: onStats,
                    icon: Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.white.withValues(alpha: 0.88),
                    ),
                  ),
                if (showAddAction)
                  IconButton(
                    onPressed: onAdd,
                    tooltip: 'Ajouter un client',
                    icon: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.white.withValues(alpha: 0.88),
                    ),
                  ),
                if (onSearch != null)
                  IconButton(
                    onPressed: onSearch,
                    tooltip: searchTooltip,
                    icon: Icon(searchIcon, color: AppColors.white, size: 26),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Champ saisie client — capsule blanche, icône colorée à gauche
// UI     : Utilisé pour GSM, nom, prénom, e-mail sur recherche et ajout.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class ClientFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const ClientFormField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6, right: 4),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bouton micro — saisie vocale (placeholder, centré au-dessus des champs)
// UI     : Cercle blanc 60 dp, bordure primary, icône mic_rounded.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class ClientMicButton extends StatelessWidget {
  final VoidCallback onTap;

  const ClientMicButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.white,
        elevation: 3,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 28),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sélecteur affichage — 10 ou 50 clients par page de résultats
// UI     : Pill blanc en bas du formulaire recherche ; chip primary si sélectionné.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class ClientPageSizeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const ClientPageSizeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Affichage',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PageChip(
                  label: '10 clients',
                  selected: value == 10,
                  onTap: () => onChanged(10),
                ),
                _PageChip(
                  label: '50 clients',
                  selected: value == 50,
                  onTap: () => onChanged(50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// UI : Option interne du ClientPageSizeSelector (10 clients / 50 clients).
/// Auteur : H.AMIZIANI
class _PageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
