import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_expense.dart';

class RecurringRepository {
  static const String _key = 'recurring_expenses';

  Future<List<RecurringExpense>> getRecurringExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => RecurringExpense.fromJson(json)).toList();
  }

  Future<void> saveRecurringExpenses(List<RecurringExpense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addRecurringExpense(RecurringExpense expense) async {
    final expenses = await getRecurringExpenses();
    expenses.add(expense);
    await saveRecurringExpenses(expenses);
  }

  Future<void> updateRecurringExpense(RecurringExpense expense) async {
    final expenses = await getRecurringExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      await saveRecurringExpenses(expenses);
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    final expenses = await getRecurringExpenses();
    expenses.removeWhere((e) => e.id == id);
    await saveRecurringExpenses(expenses);
  }

  Future<List<RecurringExpense>> getActiveRecurringExpenses() async {
    final expenses = await getRecurringExpenses();
    return expenses.where((e) => e.isActive).toList();
  }
}
