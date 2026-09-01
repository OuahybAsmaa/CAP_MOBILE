import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Écran de rédaction d'une réponse à un avis Goodays.
class GoodaysReponsePage extends StatefulWidget {
  final GoodaysAvis avis;

  const GoodaysReponsePage({super.key, required this.avis});

  static Route<void> fadeRoute(GoodaysAvis avis) => PageRouteBuilder<void>(
    pageBuilder: (_, animation, _) => FadeTransition(
      opacity: animation,
      child: GoodaysReponsePage(avis: avis),
    ),
    transitionDuration: const Duration(milliseconds: 220),
  );

  @override
  State<GoodaysReponsePage> createState() => _GoodaysReponsePageState();
}

class _GoodaysReponsePageState extends State<GoodaysReponsePage> {
  final _replyController = TextEditingController();
  final _contextController = TextEditingController();
  bool _formal = true;
  bool _emoji = false;
  bool _concise = true;
  bool _personal = true;
  bool _generating = false;

  @override
  void dispose() {
    _replyController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _generateReply() async {
    HapticFeedback.selectionClick();
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final firstName = _personal ? ' ${widget.avis.prenom}' : '';
    final ending = _emoji ? ' 😊' : '';
    _replyController.text = widget.avis.isPromoteur
        ? 'Bonjour$firstName, merci beaucoup pour votre retour. Nous sommes ravis que votre expérience en magasin vous ait satisfait. Au plaisir de vous accueillir à nouveau.$ending'
        : 'Bonjour$firstName, merci d’avoir pris le temps de nous faire part de votre expérience. Nous sommes désolés que celle-ci n’ait pas répondu à vos attentes. Votre remarque a bien été transmise à notre équipe afin d’améliorer notre service.$ending';
    setState(() => _generating = false);
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rédigez une réponse avant de l’envoyer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réponse enregistrée'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.2);
    double dp(double value) => value * scale;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: swappOverlayStyle(statusBarColor: SwappAttenteColors.headerNavy),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            _Header(dp: dp, top: top, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(dp(12), dp(12), dp(12), dp(28)),
                children: [
                  _ReviewCard(dp: dp, avis: widget.avis),
                  SizedBox(height: dp(12)),
                  _SectionCard(
                    dp: dp,
                    title: 'Préparer la réponse',
                    subtitle:
                        'Choisissez le ton qui correspond à votre message.',
                    icon: Icons.tune_rounded,
                    child: Wrap(
                      spacing: dp(8),
                      runSpacing: dp(8),
                      children: [
                        _OptionChip(
                          dp: dp,
                          label: 'Formelle',
                          icon: Icons.business_center_outlined,
                          selected: _formal,
                          onTap: () => setState(() => _formal = !_formal),
                        ),
                        _OptionChip(
                          dp: dp,
                          label: 'Avec emoji',
                          icon: Icons.emoji_emotions_outlined,
                          selected: _emoji,
                          onTap: () => setState(() => _emoji = !_emoji),
                        ),
                        _OptionChip(
                          dp: dp,
                          label: 'Concis',
                          icon: Icons.short_text_rounded,
                          selected: _concise,
                          onTap: () => setState(() => _concise = !_concise),
                        ),
                        _OptionChip(
                          dp: dp,
                          label: 'Personnalisée',
                          icon: Icons.person_outline_rounded,
                          selected: _personal,
                          onTap: () => setState(() => _personal = !_personal),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: dp(12)),
                  _SectionCard(
                    dp: dp,
                    title: 'Contexte complémentaire',
                    subtitle:
                        'Facultatif · ajoutez une information utile à la réponse.',
                    icon: Icons.lightbulb_outline_rounded,
                    child: TextField(
                      controller: _contextController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Ex. remboursement proposé, client recontacté…',
                        dp,
                      ),
                    ),
                  ),
                  SizedBox(height: dp(12)),
                  _SectionCard(
                    dp: dp,
                    title: 'Votre réponse',
                    subtitle: 'Relisez et adaptez le message avant l’envoi.',
                    icon: Icons.edit_note_rounded,
                    trailing: TextButton.icon(
                      onPressed: _generating ? null : _generateReply,
                      icon: _generating
                          ? SizedBox.square(
                              dimension: dp(15),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.auto_awesome_rounded, size: dp(17)),
                      label: Text(_generating ? 'Génération…' : 'Aide IA'),
                    ),
                    child: TextField(
                      controller: _replyController,
                      minLines: 5,
                      maxLines: 9,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        'Bonjour ${widget.avis.prenom}, merci pour votre retour…',
                        dp,
                      ),
                    ),
                  ),
                  SizedBox(height: dp(12)),
                  _SurveyCard(dp: dp, avis: widget.avis),
                  SizedBox(height: dp(18)),
                  FilledButton.icon(
                    onPressed: _sendReply,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Envoyer la réponse'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(dp(52)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(dp(14)),
                      ),
                      textStyle: TextStyle(
                        fontSize: dp(14),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, double Function(double) dp) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: EdgeInsets.all(dp(13)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(dp(12)),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(dp(12)),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(dp(12)),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final VoidCallback onBack;

  const _Header({required this.dp, required this.top, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SwappAttenteColors.headerNavy,
      padding: EdgeInsets.fromLTRB(dp(10), top + dp(6), dp(16), dp(14)),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          SizedBox(width: dp(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOODAYS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: dp(9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Répondre au client',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dp(18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: dp(9), vertical: dp(6)),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(dp(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: dp(13),
                  color: Colors.white70,
                ),
                SizedBox(width: dp(4)),
                Text(
                  'Brouillon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dp(9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysAvis avis;

  const _ReviewCard({required this.dp, required this.avis});

  @override
  Widget build(BuildContext context) {
    final accent = avis.isPromoteur ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.all(dp(16)),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(dp(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: dp(18),
            offset: Offset(0, dp(7)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: dp(21),
                backgroundColor: Colors.white,
                child: Text(
                  avis.initiales,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: dp(12),
                  ),
                ),
              ),
              SizedBox(width: dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis.nomComplet,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dp(14),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: dp(2)),
                    Text(
                      '${avis.canal} · ${DateFormat('dd/MM/yyyy à HH:mm').format(avis.date)}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: dp(9.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dp(10),
                  vertical: dp(6),
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(dp(18)),
                ),
                child: Text(
                  '${avis.nps}/10',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dp(12),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dp(14)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(dp(12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(dp(13)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Text(
              '“${avis.commentaire}”',
              style: TextStyle(
                color: Colors.white,
                fontSize: dp(12),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final double Function(double) dp;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.dp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dp(18)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: dp(34),
                height: dp(34),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(dp(10)),
                ),
                child: Icon(icon, size: dp(18), color: AppColors.primary),
              ),
              SizedBox(width: dp(9)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: dp(12.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: dp(2)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: dp(9),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: dp(13)),
          child,
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.dp,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.background,
      borderRadius: BorderRadius.circular(dp(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(22)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dp(11), vertical: dp(8)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dp(22)),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: dp(15),
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(width: dp(6)),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: dp(10),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selected) ...[
                SizedBox(width: dp(5)),
                Icon(
                  Icons.check_circle_rounded,
                  size: dp(14),
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysAvis avis;

  const _SurveyCard({required this.dp, required this.avis});

  @override
  Widget build(BuildContext context) {
    final questions = [
      ('Satisfaction globale', (avis.nps / 2).clamp(1, 5).round()),
      ('Dernière visite en magasin', avis.isPromoteur ? 4 : 3),
      ('Tenue et présentation du magasin', avis.isPromoteur ? 5 : 4),
    ];
    return _SectionCard(
      dp: dp,
      title: 'Détail du questionnaire',
      subtitle: '${questions.length} réponses associées à cet avis.',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          for (var i = 0; i < questions.length; i++) ...[
            _QuestionRow(
              dp: dp,
              index: i + 1,
              label: questions[i].$1,
              score: questions[i].$2,
            ),
            if (i < questions.length - 1)
              Divider(height: dp(22), color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final double Function(double) dp;
  final int index;
  final String label;
  final int score;

  const _QuestionRow({
    required this.dp,
    required this.index,
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: dp(28),
          height: dp(28),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: Colors.white,
              fontSize: dp(10),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: dp(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: dp(10.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: dp(6)),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= score
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i <= score
                          ? const Color(0xFFF5B301)
                          : AppColors.textMuted,
                      size: dp(19),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
