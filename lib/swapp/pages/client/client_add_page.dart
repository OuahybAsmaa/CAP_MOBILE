// =============================================================================
// CapMobile — Module Swapp — Ajout client (ClientAddPage)
// -----------------------------------------------------------------------------
// Fonctionnalité : Création fiche client — civilité, GSM, nom, prénom, e-mail.
// Design         : Même gabarit que la recherche (ClientPageScaffold + champs capsule).
// UI             : Sélecteur Mm/M. ; 4 ClientFormField ; bouton Enregistrer ;
//                  icône ✓ header = validation ; SnackBar succès puis pop.
// Spécifications : Validation nom+prénom obligatoires ; enregistrement mock local
//                  (API POST à brancher ultérieurement).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/widgets/client_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UI : Écran création client — ouvert depuis le bouton + de ClientSearchPage.
/// Auteur : H.AMIZIANI
class ClientAddPage extends StatefulWidget {
  const ClientAddPage({super.key});

  @override
  State<ClientAddPage> createState() => _ClientAddPageState();
}

class _ClientAddPageState extends State<ClientAddPage> {
  final _gsmCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _civility = 'Mm';
  bool _saving = false;

  @override
  void dispose() {
    _gsmCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// UI : Valide nom/prénom, simule l'enregistrement, SnackBar vert puis retour.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et prénom sont obligatoires')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Client $_civility ${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()} enregistré',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ClientPageScaffold(
      title: 'Ajouter un client',
      onBack: () => Navigator.pop(context),
      showStatsAction: false,
      showAddAction: false,
      onSearch: _saving ? null : _save,
      searchIcon: Icons.check_rounded,
      searchTooltip: 'Enregistrer',
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primarySoft, AppColors.bg],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CivilitySelector(
                value: _civility,
                onChanged: (v) => setState(() => _civility = v),
              ),
              const SizedBox(height: 16),
              ClientFormField(
                controller: _gsmCtrl,
                hint: 'Introduire le GSM du client',
                icon: Icons.smartphone_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primarySoft,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              ClientFormField(
                controller: _nomCtrl,
                hint: 'Nom du client',
                icon: Icons.badge_outlined,
                iconColor: AppColors.info,
                iconBg: const Color(0xFFDBEAFE),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              ClientFormField(
                controller: _prenomCtrl,
                hint: 'Prénom du client',
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.tertiary,
                iconBg: const Color(0xFFE0F2FE),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              ClientFormField(
                controller: _emailCtrl,
                hint: 'E-mail du client',
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.primaryDark,
                iconBg: AppColors.primarySoft,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  _saving ? 'Enregistrement…' : 'Enregistrer le client',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sélecteur civilité — chips Mm / M.
// UI     : Row horizontal au-dessus des champs de saisie.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _CivilitySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CivilitySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Mm',
          selected: value == 'Mm',
          onTap: () => onChanged('Mm'),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'M.',
          selected: value == 'M.',
          onTap: () => onChanged('M.'),
        ),
      ],
    );
  }
}

/// UI : Chip animé pour choix civilité (_CivilitySelector).
/// Auteur : H.AMIZIANI
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
