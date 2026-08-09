import 'package:cap_mobile/core/l10n/app_language.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/l10n/locale_provider.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageMenuButton extends ConsumerWidget {
  final double iconSize;
  final Color iconColor;

  const LanguageMenuButton({
    super.key,
    this.iconSize = 22,
    this.iconColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final l10n = context.l10n;

    return PopupMenuButton<AppLanguage>(
      tooltip: l10n.language,
      padding: EdgeInsets.zero,
      icon: Icon(Icons.language, color: iconColor, size: iconSize),
      onSelected: (lang) =>
          ref.read(localeProvider.notifier).setLanguage(lang),
      itemBuilder: (_) => AppLanguage.values
          .map(
            (lang) => PopupMenuItem(
              value: lang,
              child: Row(
                children: [
                  if (lang == current)
                    Icon(Icons.check, size: 16, color: AppColors.primary)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(lang.label),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
