import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';

class BudgetRepository {
  static const String _key = 'budgets';

  Future<List<Budget>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);

    if (data == null) {
      final defaults = Budget.getDefaultBudgets();
      await saveBudgets(defaults);
      return defaults;
    }

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Budget.fromJson(json)).toList();
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(budgets.map((b) => b.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addBudget(Budget budget) async {
    final budgets = await getBudgets();
    budgets.add(budget);
    await saveBudgets(budgets);
  }

  Future<void> updateBudget(Budget budget) async {
    final budgets = await getBudgets();
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      budgets[index] = budget;
      await saveBudgets(budgets);
    }
  }

  Future<void> deleteBudget(String id) async {
    final budgets = await getBudgets();
    budgets.removeWhere((b) => b.id == id);
    await saveBudgets(budgets);
  }
}
