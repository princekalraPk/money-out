import 'package:intl/intl.dart';

const expenseCategories = <String>[
  'Rent',
  'Salaries',
  'Electricity',
  'Office supplies',
  'Travel',
  'Internet & phone',
  'Repairs & maintenance',
  'Food & refreshments',
  'Professional fees',
  'Taxes & bank charges',
  'Other expense',
];

const paymentModes = <String>[
  'Cash',
  'Bank transfer',
  'UPI',
  'Card',
  'Cheque',
];

final currencyFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final dayFormat = DateFormat('d MMM yyyy');
final monthFormat = DateFormat('MMMM yyyy');
final _dbDate = DateFormat('yyyy-MM-dd');

String toDbDate(DateTime d) => _dbDate.format(d);

class Expense {
  Expense({
    this.id,
    required this.spentOn,
    required this.amount,
    required this.category,
    required this.paidFrom,
    this.paidTo,
    this.note,
    this.refNo,
  });

  final String? id;
  final DateTime spentOn;
  final double amount;
  final String category;
  final String paidFrom;
  final String? paidTo;
  final String? note;
  final String? refNo;

  bool get isNew => id == null;

  factory Expense.blank() => Expense(
        spentOn: DateTime.now(),
        amount: 0,
        category: expenseCategories.first,
        paidFrom: paymentModes.first,
      );

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      spentOn: DateTime.parse(map['spent_on'] as String),
      amount: (map['amount'] as num).toDouble(),
      category: (map['category'] as String?) ?? 'Other expense',
      paidFrom: (map['paid_from'] as String?) ?? 'Cash',
      paidTo: map['paid_to'] as String?,
      note: map['note'] as String?,
      refNo: map['ref_no'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'spent_on': toDbDate(spentOn),
        'amount': amount,
        'category': category,
        'paid_from': paidFrom,
        'paid_to': _clean(paidTo),
        'note': _clean(note),
        'ref_no': _clean(refNo),
      };

  Expense copyWith({
    DateTime? spentOn,
    double? amount,
    String? category,
    String? paidFrom,
    String? paidTo,
    String? note,
    String? refNo,
  }) {
    return Expense(
      id: id,
      spentOn: spentOn ?? this.spentOn,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidFrom: paidFrom ?? this.paidFrom,
      paidTo: paidTo ?? this.paidTo,
      note: note ?? this.note,
      refNo: refNo ?? this.refNo,
    );
  }

  static String? _clean(String? v) {
    final s = v?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
