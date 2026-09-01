import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _blue = Color(0xFF2855F5), _navy = Color(0xFF031D54);
const _muted = Color(0xFF69738C);
const _canvas = Color(0xFFF6F8FC), _green = Color(0xFF08B56B);
const _orange = Color(0xFFFFA000), _red = Color(0xFFF4323D);

enum TicketStatus { enCours, attribue, resolu, cloture }

extension TicketStatusUi on TicketStatus {
  String get label => switch (this) {
    TicketStatus.enCours => 'En cours',
    TicketStatus.attribue => 'Attribué',
    TicketStatus.resolu => 'Résolu',
    TicketStatus.cloture => 'Clôturé',
  };
  Color get color => switch (this) {
    TicketStatus.enCours => _blue,
    TicketStatus.attribue => _orange,
    TicketStatus.resolu => _green,
    TicketStatus.cloture => const Color(0xFF7D5CFF),
  };
  IconData get icon => switch (this) {
    TicketStatus.enCours => Icons.sync_rounded,
    TicketStatus.attribue => Icons.person_rounded,
    TicketStatus.resolu => Icons.check_circle_outline_rounded,
    TicketStatus.cloture => Icons.lock_outline_rounded,
  };
}

class Ticket {
  Ticket({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.assignee,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    required this.accent,
  });
  final int id;
  final String author, title, description, assignee, dueDate;
  final DateTime createdAt;
  TicketStatus status;
  final Color accent;
}

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => TicketsPage(key: UniqueKey()),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 260),
  );
  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  TicketStatus? _filter;
  String _query = '';
  bool _searching = false, _newestFirst = true;
  final _tickets = <Ticket>[
    Ticket(
      id: 408,
      author: 'Vincent Parisot',
      title: 'PILOMAG TBL_JNL',
      description: 'Améliorer le champ NUM_POSTE = 22 dans TBL_JNL',
      assignee: 'Cedric La Torre',
      createdAt: DateTime(2023, 8, 31, 10, 9),
      dueDate: '31/08/23',
      status: TicketStatus.attribue,
      accent: _blue,
    ),
    Ticket(
      id: 33232,
      author: 'Fanny Zuccato',
      title: 'Problème son ordinateur',
      description:
          'Bonjour, je rencontre des difficultés avec mon ordinateur quand…',
      assignee: 'David De Menech',
      createdAt: DateTime(2026, 6, 30, 15, 46),
      dueDate: '02/07/26',
      status: TicketStatus.attribue,
      accent: _orange,
    ),
    Ticket(
      id: 19040,
      author: 'Amine Riahi',
      title: 'GlobalPOS',
      description: 'Ce ticket permet de suivre le projet GlobalPOS',
      assignee: 'Hattef Loussaief',
      createdAt: DateTime(2025, 4, 30, 11, 1),
      dueDate: '30/04/25',
      status: TicketStatus.enCours,
      accent: _green,
    ),
    Ticket(
      id: 34984,
      author: 'Fanny Zuccato',
      title: 'Préparation nouvelle promo',
      description: 'Bonjour, j’ai 2 promos qui ouvrent prochainement…',
      assignee: 'David De Menech',
      createdAt: DateTime(2025, 7, 27, 14, 10),
      dueDate: '--/--/--',
      status: TicketStatus.attribue,
      accent: const Color(0xFF7D5CFF),
    ),
    Ticket(
      id: 36706,
      author: 'Khaoula Bouazzaoui',
      title: 'Déblocage BIP Zébra',
      description: 'Déblocage du bippage des retours pour le magasin.',
      assignee: 'Agent Helpdesk 6',
      createdAt: DateTime(2026, 8, 18, 15, 1),
      dueDate: '18/08/26',
      status: TicketStatus.resolu,
      accent: _green,
    ),
    Ticket(
      id: 36490,
      author: 'Hicham Khayari',
      title: 'Zebra',
      description: 'Le magasin a reçu le deuxième terminal Zebra.',
      assignee: 'Support IT',
      createdAt: DateTime(2026, 8, 15, 9, 35),
      dueDate: '15/08/26',
      status: TicketStatus.cloture,
      accent: const Color(0xFF7D5CFF),
    ),
  ];

  int _count(TicketStatus s) => _tickets.where((t) => t.status == s).length;
  List<Ticket> get _visible {
    final q = _query.trim().toLowerCase();
    final result = _tickets
        .where(
          (t) =>
              (_filter == null || t.status == _filter) &&
              (q.isEmpty ||
                  t.title.toLowerCase().contains(q) ||
                  t.author.toLowerCase().contains(q) ||
                  '${t.id}'.contains(q)),
        )
        .toList();
    result.sort(
      (a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _visible;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _canvas,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _stats()),
            SliverToBoxAdapter(child: _controls()),
            if (tickets.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyTickets(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                sliver: SliverList.separated(
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TicketCard(
                    ticket: tickets[i],
                    onOpen: () => _details(tickets[i]),
                    onDelete: () => _delete(tickets[i]),
                    onEdit: () => _textDialog(
                      'Modifier #${tickets[i].id}',
                      'Ticket mis à jour.',
                    ),
                    onComment: () => _textDialog(
                      'Commenter #${tickets[i].id}',
                      'Commentaire ajouté.',
                    ),
                    onClose: () => setState(
                      () => tickets[i].status = TicketStatus.cloture,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
    padding: EdgeInsets.fromLTRB(
      10,
      MediaQuery.paddingOf(context).top + 10,
      18,
      40,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_navy, Color(0xFF062A75), _blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes Tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gérez et suivez facilement vos tickets',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _searching = !_searching),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .1),
                side: BorderSide(color: Colors.white.withValues(alpha: .22)),
              ),
              icon: Icon(
                _searching ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_searching)
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher un ticket…',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _create,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4965FF),
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nouveau ticket',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _stats() => Transform.translate(
    offset: const Offset(0, -22),
    child: SizedBox(
      height: 112,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            value: _tickets.length,
            label: 'Total tickets',
            icon: Icons.assignment_outlined,
            color: _blue,
          ),
          _StatCard(
            value: _count(TicketStatus.enCours) + _count(TicketStatus.attribue),
            label: 'En cours',
            icon: Icons.schedule_rounded,
            color: _orange,
          ),
          _StatCard(
            value: _count(TicketStatus.resolu),
            label: 'Résolus',
            icon: Icons.check_circle_outline_rounded,
            color: _green,
          ),
          _StatCard(
            value: _count(TicketStatus.cloture),
            label: 'Clôturés',
            icon: Icons.lock_outline_rounded,
            color: _red,
          ),
        ],
      ),
    ),
  );

  Widget _controls() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Filter(
                label: 'Tous (${_tickets.length})',
                selected: _filter == null,
                tap: () => setState(() => _filter = null),
              ),
              _Filter(
                label:
                    'En cours (${_count(TicketStatus.enCours) + _count(TicketStatus.attribue)})',
                selected:
                    _filter == TicketStatus.enCours ||
                    _filter == TicketStatus.attribue,
                tap: () => setState(() => _filter = TicketStatus.enCours),
              ),
              _Filter(
                label: 'Résolus (${_count(TicketStatus.resolu)})',
                selected: _filter == TicketStatus.resolu,
                tap: () => setState(() => _filter = TicketStatus.resolu),
              ),
              _Filter(
                label: 'Clôturés (${_count(TicketStatus.cloture)})',
                selected: _filter == TicketStatus.cloture,
                tap: () => setState(() => _filter = TicketStatus.cloture),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${_visible.length} résultat(s)',
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => setState(() => _newestFirst = !_newestFirst),
              icon: Icon(_newestFirst ? Icons.south : Icons.north, size: 16),
              label: Text(_newestFirst ? 'Plus récent' : 'Plus ancien'),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: _advancedFilter,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _create() async {
    final t = await showModalBottomSheet<Ticket>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewTicketSheet(nextId: 40000 + _tickets.length),
    );
    if (t != null) setState(() => _tickets.insert(0, t));
  }

  void _delete(Ticket t) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Supprimer le ticket ?'),
      content: Text('Le ticket #${t.id} sera retiré.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(c);
            setState(() => _tickets.remove(t));
          },
          style: FilledButton.styleFrom(backgroundColor: _red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  void _details(Ticket t) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _Details(ticket: t),
  );
  void _textDialog(String title, String success) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: const TextField(
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Votre texte…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(c);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(success)));
          },
          child: const Text('Valider'),
        ),
      ],
    ),
  );
  void _advancedFilter() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtrer les tickets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            ...TicketStatus.values.map(
              (s) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: s.color.withValues(alpha: .12),
                  child: Icon(s.icon, color: s.color),
                ),
                title: Text(s.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(c);
                  setState(() => _filter = s);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 142,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE7EAF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x101B2850),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.tap,
  });
  final String label;
  final bool selected;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? _blue : const Color(0xFFE2E6EF)),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x332855F5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onOpen,
    required this.onDelete,
    required this.onEdit,
    required this.onComment,
    required this.onClose,
  });
  final Ticket ticket;
  final VoidCallback onOpen, onDelete, onEdit, onComment, onClose;
  String get initials =>
      ticket.author.split(' ').take(2).map((w) => w[0]).join().toUpperCase();
  String get date =>
      '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}/${ticket.createdAt.year.toString().substring(2)} ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: ticket.accent, width: 5),
            top: const BorderSide(color: Color(0xFFE9ECF3)),
            right: const BorderSide(color: Color(0xFFE9ECF3)),
            bottom: const BorderSide(color: Color(0xFFE9ECF3)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E1B2850),
              blurRadius: 15,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: ticket.accent.withValues(alpha: .12),
                  foregroundColor: ticket.accent,
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.author.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        date,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      Text(
                        '#Ticket:${ticket.id}',
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _Status(status: ticket.status),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (v) => v == 'delete' ? onDelete() : onOpen(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'open', child: Text('Voir le détail')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent, size: 16, color: _muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ticket.assignee.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _Action(Icons.delete_outline, _red, onDelete),
                _Action(Icons.chat_bubble_outline, _blue, onComment),
                _Action(Icons.edit_outlined, _green, onEdit),
                _Action(Icons.lock_outline, Colors.grey, onClose),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: _red,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Échéance : ${ticket.dueDate}',
                    style: const TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final TicketStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: status.color.withValues(alpha: .28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, color: status.color, size: 14),
        const SizedBox(width: 3),
        Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.color, this.tap);
  final IconData icon;
  final Color color;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 5),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(30),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.ticket});
  final Ticket ticket;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ticket #${ticket.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Status(status: ticket.status),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            ticket.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            ticket.description,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(ticket.author),
            subtitle: const Text('Demandeur'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.support_agent)),
            title: Text(ticket.assignee),
            subtitle: const Text('Agent assigné'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ),
  );
}

class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet({required this.nextId});
  final int nextId;
  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final form = GlobalKey<FormState>(),
      title = TextEditingController(),
      description = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nouveau ticket',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: title,
            validator: (v) => v == null || v.trim().length < 4
                ? 'Indiquez un titre précis'
                : null,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: description,
            minLines: 4,
            maxLines: 6,
            validator: (v) => v == null || v.trim().length < 8
                ? 'Décrivez votre demande'
                : null,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.pop(
                context,
                Ticket(
                  id: widget.nextId,
                  author: 'Hicham Khayari',
                  title: title.text.trim(),
                  description: description.text.trim(),
                  assignee: 'Non attribué',
                  createdAt: DateTime.now(),
                  dueDate: '--/--/--',
                  status: TicketStatus.enCours,
                  accent: _blue,
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Créer le ticket'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 65, color: _muted),
        SizedBox(height: 12),
        Text(
          'Aucun ticket trouvé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(
          'Modifiez les filtres ou la recherche.',
          style: TextStyle(color: _muted),
        ),
      ],
    ),
  );
}
