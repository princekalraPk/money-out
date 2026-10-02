import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import 'expense_form.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _service = ExpenseService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Expense> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.forMonth(_month);
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = readableError(e);
        _loading = false;
      });
    }
  }

  void _shiftMonth(int by) {
    setState(() => _month = DateTime(_month.year, _month.month + by));
    _load();
  }

  Future<void> _openForm([Expense? expense]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExpenseForm(expense: expense),
    );
    if (saved == true) _load();
  }

  double get _total => _items.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get _byCategory {
    final map = <String, double>{};
    for (final e in _items) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _showCategoryBreakdown() {
    final data = _byCategory;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spending in ${monthFormat.format(_month)}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (data.isEmpty)
                const Text('Nothing recorded this month.')
              else
                ...data.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(e.key)),
                        Text(currencyFormat.format(e.value),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<Expense>>{};
    for (final e in _items) {
      grouped.putIfAbsent(dayFormat.format(e.spentOn), () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Out'),
        actions: [
          IconButton(
            tooltip: 'Spending by category',
            onPressed: _showCategoryBreakdown,
            icon: const Icon(Icons.pie_chart_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'refresh') _load();
              if (v == 'signout') _signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            _MonthBar(
              month: _month,
              total: _total,
              count: _items.length,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_error != null) {
                    return _Message(
                      icon: Icons.cloud_off,
                      title: 'Could not load entries',
                      body: _error!,
                      action: FilledButton(
                          onPressed: _load, child: const Text('Try again')),
                    );
                  }
                  if (_items.isEmpty) {
                    return _Message(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses in ${monthFormat.format(_month)}',
                      body: 'Tap "Add expense" to record the first payment.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                    children: [
                      for (final day in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(day.key,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.outline)),
                              Text(
                                currencyFormat.format(day.value
                                    .fold<double>(0, (s, e) => s + e.amount)),
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < day.value.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                _ExpenseTile(
                                  expense: day.value[i],
                                  onTap: () => _openForm(day.value[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Text('Designed by AnnexCode',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.total,
    required this.count,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final double total;
  final int count;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Text(monthFormat.format(month),
                  style: theme.textTheme.titleMedium),
              IconButton(
                  onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Text(currencyFormat.format(total),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('$count ${count == 1 ? 'payment' : 'payments'} this month',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = [
      expense.category,
      expense.paidFrom,
      if (expense.paidTo != null) expense.paidTo!,
    ].join('  ·  ');

    return ListTile(
      onTap: onTap,
      title: Text(
        expense.note?.isNotEmpty == true ? expense.note! : expense.category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall),
      trailing: Text(
        currencyFormat.format(expense.amount),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      children: [
        Icon(icon, size: 36, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline)),
        if (action != null) ...[
          const SizedBox(height: 16),
          Center(child: action!),
        ],
      ],
    );
  }
}
