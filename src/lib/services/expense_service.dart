import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';

/// All reads and writes for the `expenses` table.
/// Row Level Security keeps every user on their own rows.
class ExpenseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Expense>> forMonth(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);

    final rows = await _client
        .from('expenses')
        .select()
        .gte('spent_on', toDbDate(from))
        .lte('spent_on', toDbDate(to))
        .order('spent_on', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .map((row) => Expense.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> save(Expense expense) async {
    if (expense.isNew) {
      await _client.from('expenses').insert(expense.toMap());
    } else {
      await _client.from('expenses').update(expense.toMap()).eq('id', expense.id!);
    }
  }

  Future<void> remove(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}

String readableError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '42501' || error.message.contains('row-level security')) {
      return 'You do not have permission to change this entry.';
    }
    if (error.code == '42P01') {
      return 'The expenses table is missing. Run supabase/schema.sql first.';
    }
    return error.message;
  }
  return 'Something went wrong. Check your internet connection and try again.';
}
