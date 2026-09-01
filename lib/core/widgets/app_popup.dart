// =============================================================================
// CapMobile — Popup unique paramétrable (tout le projet)
// -----------------------------------------------------------------------------
// Un seul chrome visuel pour tous les dialogues : icône circulaire, titre,
// message, pastille, corps libre, 0 à N boutons.
//
// Cas couverts :
//   AppPopup.info     — message + OK
//   AppPopup.confirm  — Annuler / Valider
//   AppPopup.danger   — Annuler / Supprimer (bouton rouge)
//   AppPopup.choice   — Oui (vert) / Non (rouge)
//   AppPopup.input    — champ texte + Annuler / Valider
//   AppPopup.loading  — spinner bloquant (fermer avec AppPopup.hide)
//   AppPopup.show     — tout le reste (liste, RFID, contenu custom)
//
// Les pickers très spécifiques (magasin, lecteur RFID) passent leur liste
// dans [body] ; le zoom photo reste un viewer plein écran à part.
// Auteur : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleur / icône par défaut du badge.
enum AppPopupTone { info, success, warning, danger, primary, loading }

/// Apparence d'un bouton d'action.
enum AppPopupActionStyle { filled, outlined, text, success, danger }

/// Bouton du pied de popup. [value] est renvoyé par [Navigator.pop] au tap.
class AppPopupAction<T> {
  final String label;
  final AppPopupActionStyle style;
  final T? value;
  final IconData? icon;
  final bool pop;

  /// Si renseigné, appelé à la place du pop (le callback gère la fermeture).
  final VoidCallback? onTap;

  const AppPopupAction({
    required this.label,
    this.style = AppPopupActionStyle.filled,
    this.value,
    this.icon,
    this.pop = true,
    this.onTap,
  });
}

/// Palette dérivée du [AppPopupTone].
class _ToneColors {
  final Color accent;
  final Color badge;

  const _ToneColors(this.accent, this.badge);

  static _ToneColors of(AppPopupTone tone) => switch (tone) {
        AppPopupTone.info => const _ToneColors(
            AppColors.info,
            AppColors.primarySoft,
          ),
        AppPopupTone.success => const _ToneColors(
            AppColors.success,
            Color(0xFFD1FAE5),
          ),
        AppPopupTone.warning => const _ToneColors(
            AppColors.warning,
            Color(0xFFFEF3C7),
          ),
        AppPopupTone.danger => const _ToneColors(
            AppColors.error,
            Color(0xFFFEE2E2),
          ),
        AppPopupTone.primary => const _ToneColors(
            AppColors.primary,
            AppColors.primarySoft,
          ),
        AppPopupTone.loading => const _ToneColors(
            AppColors.primary,
            AppColors.primarySoft,
          ),
      };
}

/// Point d'entrée unique des popups CapMobile.
abstract final class AppPopup {
  AppPopup._();

  static IconData _iconFor(AppPopupTone tone) => switch (tone) {
        AppPopupTone.info => Icons.info_outline_rounded,
        AppPopupTone.success => Icons.check_circle_rounded,
        AppPopupTone.warning => Icons.pending_actions_rounded,
        AppPopupTone.danger => Icons.warning_amber_rounded,
        AppPopupTone.primary => Icons.help_outline_rounded,
        AppPopupTone.loading => Icons.hourglass_top_rounded,
      };

  /// Popup générique — tous les autres helpers s'appuient dessus.
  static Future<T?> show<T>({
    required BuildContext context,
    AppPopupTone tone = AppPopupTone.primary,
    IconData? icon,
    String? title,
    String? message,
    String? badge,
    Widget? body,
    List<AppPopupAction<T>> actions = const [],
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    bool showIcon = true,
    double maxWidth = 340,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.45),
      useRootNavigator: useRootNavigator,
      builder: (ctx) => _AppPopupShell<T>(
        tone: tone,
        icon: icon ?? _iconFor(tone),
        title: title,
        message: message,
        badge: badge,
        body: body,
        actions: actions,
        showIcon: showIcon,
        maxWidth: maxWidth,
      ),
    );
  }

  /// Message d'information — un bouton OK.
  static Future<void> info(
    BuildContext context, {
    required String title,
    String? message,
    String? badge,
    Widget? body,
    IconData? icon,
    String okLabel = 'OK',
  }) {
    return show<void>(
      context: context,
      tone: AppPopupTone.info,
      icon: icon,
      title: title,
      message: message,
      badge: badge,
      body: body,
      actions: [AppPopupAction<void>(label: okLabel)],
    );
  }

  /// Succès — un bouton OK vert.
  static Future<void> success(
    BuildContext context, {
    required String title,
    String? message,
    String? badge,
    Widget? body,
    IconData? icon,
    String okLabel = 'OK',
  }) {
    return show<void>(
      context: context,
      tone: AppPopupTone.success,
      icon: icon,
      title: title,
      message: message,
      badge: badge,
      body: body,
      actions: [
        AppPopupAction<void>(
          label: okLabel,
          style: AppPopupActionStyle.success,
        ),
      ],
    );
  }

  /// Confirmation Annuler / Valider. Retourne true si validé.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String? badge,
    Widget? body,
    IconData? icon,
    AppPopupTone tone = AppPopupTone.primary,
    String cancelLabel = 'Annuler',
    String confirmLabel = 'Valider',
    bool barrierDismissible = true,
  }) async {
    final result = await show<bool>(
      context: context,
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      badge: badge,
      body: body,
      barrierDismissible: barrierDismissible,
      actions: [
        AppPopupAction(
          label: cancelLabel,
          style: AppPopupActionStyle.outlined,
          value: false,
        ),
        AppPopupAction(label: confirmLabel, value: true),
      ],
    );
    return result == true;
  }

  /// Confirmation destructive Annuler / Supprimer. Retourne true si confirmé.
  static Future<bool> danger(
    BuildContext context, {
    required String title,
    String? message,
    String? badge,
    Widget? body,
    IconData? icon,
    String cancelLabel = 'Annuler',
    String confirmLabel = 'Supprimer',
    bool barrierDismissible = true,
  }) async {
    final result = await show<bool>(
      context: context,
      tone: AppPopupTone.danger,
      icon: icon ?? Icons.delete_outline_rounded,
      title: title,
      message: message,
      badge: badge,
      body: body,
      barrierDismissible: barrierDismissible,
      actions: [
        AppPopupAction(
          label: cancelLabel,
          style: AppPopupActionStyle.outlined,
          value: false,
        ),
        AppPopupAction(
          label: confirmLabel,
          style: AppPopupActionStyle.danger,
          value: true,
        ),
      ],
    );
    return result == true;
  }

  /// Choix Oui / Non (reprises OT, retours). Retourne true si Oui.
  static Future<bool> choice(
    BuildContext context, {
    required String title,
    String? message,
    String? badge,
    Widget? body,
    IconData? icon,
    AppPopupTone tone = AppPopupTone.warning,
    String yesLabel = 'Oui',
    String noLabel = 'Non',
    bool barrierDismissible = false,
  }) async {
    final result = await show<bool>(
      context: context,
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      badge: badge,
      body: body,
      barrierDismissible: barrierDismissible,
      actions: [
        AppPopupAction(
          label: yesLabel,
          style: AppPopupActionStyle.success,
          value: true,
        ),
        AppPopupAction(
          label: noLabel,
          style: AppPopupActionStyle.danger,
          value: false,
        ),
      ],
    );
    return result == true;
  }

  /// Saisie texte. Retourne la valeur trimée, ou null si annulé.
  static Future<String?> input(
    BuildContext context, {
    required String title,
    String? message,
    String? hint,
    String initialValue = '',
    IconData? icon,
    AppPopupTone tone = AppPopupTone.primary,
    String cancelLabel = 'Annuler',
    String confirmLabel = 'Valider',
    String? Function(String value)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.45),
      builder: (ctx) => _AppPopupInput(
        tone: tone,
        icon: icon ?? Icons.edit_rounded,
        title: title,
        message: message,
        hint: hint,
        initialValue: initialValue,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        maxLines: maxLines,
      ),
    );
  }

  /// Overlay de chargement — non dismissible. Fermer avec [hide].
  static void loading(
    BuildContext context, {
    String message = 'Chargement…',
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.45),
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: _AppPopupShell<void>(
          tone: AppPopupTone.loading,
          icon: Icons.hourglass_top_rounded,
          title: message,
          showIcon: false,
          body: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  /// Ferme le popup courant (chargement ou autre) via le root navigator.
  static void hide(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}

// ---------------------------------------------------------------------------
// Coque visuelle unique
// ---------------------------------------------------------------------------
class _AppPopupShell<T> extends StatelessWidget {
  final AppPopupTone tone;
  final IconData icon;
  final String? title;
  final String? message;
  final String? badge;
  final Widget? body;
  final List<AppPopupAction<T>> actions;
  final bool showIcon;
  final double maxWidth;

  const _AppPopupShell({
    required this.tone,
    required this.icon,
    this.title,
    this.message,
    this.badge,
    this.body,
    this.actions = const [],
    this.showIcon = true,
    this.maxWidth = 340,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ToneColors.of(tone);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight =
        screenHeight - MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 18,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.24),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: keyboardOpen ? 10 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: (availableHeight - (keyboardOpen ? 20 : 48)).clamp(
            180.0,
            screenHeight,
          ).toDouble(),
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              keyboardOpen ? 16 : 26,
              22,
              keyboardOpen ? 14 : 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Container(
                    width: keyboardOpen ? 52 : 64,
                    height: keyboardOpen ? 52 : 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.badge,
                          colors.accent.withValues(alpha: 0.18),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: colors.accent,
                      size: keyboardOpen ? 27 : 34,
                    ),
                  ),
                  SizedBox(height: keyboardOpen ? 10 : 18),
                ],
                if (title != null)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                if (message != null) ...[
                  SizedBox(height: keyboardOpen ? 5 : 10),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              if (badge != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
              if (body != null) ...[
                const SizedBox(height: 14),
                body!,
              ],
              if (actions.isNotEmpty) ...[
                SizedBox(height: keyboardOpen ? 14 : 22),
                _ActionRow<T>(actions: actions),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow<T> extends StatelessWidget {
  final List<AppPopupAction<T>> actions;

  const _ActionRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.length == 1) {
      return SizedBox(
        width: double.infinity,
        child: _ActionButton<T>(action: actions.first),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _ActionButton<T>(action: actions[i])),
        ],
      ],
    );
  }
}

class _ActionButton<T> extends StatelessWidget {
  final AppPopupAction<T> action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = switch (action.style) {
      AppPopupActionStyle.filled => AppColors.primary,
      AppPopupActionStyle.outlined => AppColors.textSecondary,
      AppPopupActionStyle.text => AppColors.primary,
      AppPopupActionStyle.success => AppColors.success,
      AppPopupActionStyle.danger => AppColors.error,
    };

    void handleTap() {
      HapticFeedback.lightImpact();
      if (action.onTap != null) {
        action.onTap!();
        return;
      }
      if (action.pop) {
        Navigator.of(context).pop(action.value);
      }
    }

    if (action.style == AppPopupActionStyle.outlined ||
        action.style == AppPopupActionStyle.text) {
      return OutlinedButton(
        onPressed: handleTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          action.label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.45),
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variante saisie — le champ vit dans un State pour Valider / clavier
// ---------------------------------------------------------------------------
class _AppPopupInput extends StatefulWidget {
  final AppPopupTone tone;
  final IconData icon;
  final String title;
  final String? message;
  final String? hint;
  final String initialValue;
  final String cancelLabel;
  final String confirmLabel;
  final String? Function(String value)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final int maxLines;

  const _AppPopupInput({
    required this.tone,
    required this.icon,
    required this.title,
    required this.initialValue,
    required this.cancelLabel,
    required this.confirmLabel,
    this.message,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  State<_AppPopupInput> createState() => _AppPopupInputState();
}

class _AppPopupInputState extends State<_AppPopupInput> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _AppPopupShell<String>(
      tone: widget.tone,
      icon: widget.icon,
      title: widget.title,
      message: widget.message,
      body: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (widget.validator != null) return widget.validator!(text);
            if (text.isEmpty) return 'Champ obligatoire';
            return null;
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: AppColors.primarySoft.withValues(alpha: 0.52),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.32),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ),
      actions: [
        AppPopupAction(
          label: widget.cancelLabel,
          style: AppPopupActionStyle.outlined,
        ),
        AppPopupAction(
          label: widget.confirmLabel,
          onTap: _submit,
        ),
      ],
    );
  }
}
