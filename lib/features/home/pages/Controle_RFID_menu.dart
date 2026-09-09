import 'package:flutter/material.dart';
import 'package:cap_mobile/features/QC/pages/qc_page.dart';
import '../../exp_control/pages/exp_control_page.dart';
import '../../pva_control/pages/pva_control_page.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';

class _C {
  static const bg = Color(0xFFF0F2FF);
  static const primaryDark = Color(0xFF1A237E);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textMuted = Color(0xFF9CA3AF);
}

class ControlRfidMenuPage extends StatelessWidget {
  const ControlRfidMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        foregroundColor: _C.primaryDark,
        title: Text(
          context.f.controlRfidMenuTitle,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _optionCard(
              context,
              title: context.f.controlRfidMenuQcTitle,
              subtitle: context.f.controlRfidMenuQcSubtitle,
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              page: const QcRfidPage(),
            ),
            const SizedBox(height: 16),
            _optionCard(
              context,
              title: context.f.controlRfidMenuExpTitle,
              subtitle: context.f.controlRfidMenuExpSubtitle,
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF01667E),
              bgColor: const Color(0xFFE0F2FE),
              page: const ExpControlPage(),
            ),
            const SizedBox(height: 16),
            _optionCard(
              context,
              title: context.f.controlRfidMenuPvaTitle,
              subtitle: context.f.controlRfidMenuPvaSubtitle,
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF7B1FA2),
              bgColor: const Color(0xFFF3E5F5),
              page: const PvaControlPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Color bgColor,
        required Widget page,
      }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: _C.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.textMuted),
          ],
        ),
      ),
    );
  }
}