import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _service = ExpenseService();
  final _formKey = GlobalKey<FormState>();
  late Expense _draft;
  late final TextEditingController _amount;
  late final TextEditingController _paidTo;
  late final TextEditingController _note;
  late final TextEditingController _ref;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _draft = widget.expense ?? Expense.blank();
    _amount = TextEditingController(
        text: _draft.amount > 0 ? _draft.amount.toStringAsFixed(2) : '');
    _paidTo = TextEditingController(text: _draft.paidTo ?? '');
    _note = TextEditingController(text: _draft.note ?? '');
    _ref = TextEditingController(text: _draft.refNo ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _paidTo.dispose();
    _note.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.spentOn,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _draft = _draft.copyWith(spentOn: picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final expense = _draft.copyWith(
      amount: double.parse(_amount.text.trim()),
      paidTo: _paidTo.text,
      note: _note.text,
      refNo: _ref.text,
    );
    try {
      await _service.save(expense);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = readableError(e);
          _busy = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('It will be removed for good.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _service.remove(_draft.id!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = readableError(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _draft.isNew ? 'New expense' : 'Edit expense',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                autofocus: _draft.isNew,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ '),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dayFormat.format(_draft.spentOn)),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Category',
                value: _draft.category,
                options: expenseCategories,
                onSelected: (v) =>
                    setState(() => _draft = _draft.copyWith(category: v)),
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Paid by',
                value: _draft.paidFrom,
                options: paymentModes,
                onSelected: (v) =>
                    setState(() => _draft = _draft.copyWith(paidFrom: v)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidTo,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Paid to (optional)',
                    hintText: 'Shop, vendor or person'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Particulars (optional)',
                    hintText: 'e.g. September office rent'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ref,
                decoration: const InputDecoration(
                    labelText: 'Bill / ref no. (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_draft.isNew ? 'Save expense' : 'Save changes'),
                ),
              ),
              if (!_draft.isNew)
                TextButton(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete expense'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tap-to-choose field. Used instead of a dropdown so the list is easy to
/// read on a phone.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing: option == value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}
