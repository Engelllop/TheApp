import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_app/data/models/recurring_expense.dart';
import 'package:the_app/data/models/budget.dart';
import 'package:the_app/data/repositories/recurring_repository.dart';
import 'package:the_app/data/repositories/budget_repository.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';

class NotificationService {
  static const String _enabledKey = 'notifications_enabled';
  static const String _lastCheckKey = 'notification_last_check';
  static const String _reminderDaysKey = 'reminder_days_before';

  bool _enabled = true;
  int _reminderDays = 3;
  List<Map<String, dynamic>> _pendingNotifications = [];

  bool get enabled => _enabled;
  List<Map<String, dynamic>> get pendingNotifications => _pendingNotifications;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _reminderDays = prefs.getInt(_reminderDaysKey) ?? 3;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setReminderDays(int days) async {
    _reminderDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderDaysKey, days);
  }

  Future<void> checkAndGenerateNotifications() async {
    if (!_enabled) return;

    _pendingNotifications = [];
    final now = DateTime.now();

    final recurringRepo = RecurringRepository();
    final budgetRepo = BudgetRepository();
    final transactionRepo = TransactionRepository();

    final recurringExpenses = await recurringRepo.getRecurringExpenses();
    final budgets = await budgetRepo.getBudgets();
    final transactions = await transactionRepo.getTransactions();

    for (final expense in recurringExpenses) {
      if (!expense.isActive) continue;

      final nextDue = _calculateNextDueDate(expense);
      final daysUntilDue = nextDue.difference(now).inDays;

      if (daysUntilDue >= 0 && daysUntilDue <= _reminderDays) {
        _pendingNotifications.add({
          'type': 'recurring',
          'title': 'Pago pendiente: ${expense.name}',
          'body':
              'Vence en $daysUntilDue día${daysUntilDue == 1 ? '' : 's'} - \$${expense.amount.toStringAsFixed(2)}',
          'iconData': 0xe0e0,
          'color': 0xFFe94560,
          'daysUntil': daysUntilDue,
          'expenseId': expense.id,
        });
      }
    }

    final thisMonthExpenses = transactions
        .where((t) =>
            t.isExpense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    for (final budget in budgets) {
      final spent = thisMonthExpenses;
      final remaining = budget.limit - spent;
      final percentUsed = budget.limit > 0 ? (spent / budget.limit * 100) : 0;

      if (percentUsed >= 80 && percentUsed < 100) {
        _pendingNotifications.add({
          'type': 'budget_warning',
          'title': 'Presupuesto casi lleno: ${budget.category}',
          'body':
              'Has usado ${percentUsed.toStringAsFixed(0)}% - Quedan \$${remaining.toStringAsFixed(2)}',
          'iconData': 0xe002,
          'color': 0xFFe9c46a,
          'percentUsed': percentUsed,
          'budgetId': budget.id,
        });
      } else if (percentUsed >= 100) {
        _pendingNotifications.add({
          'type': 'budget_exceeded',
          'title': 'Presupuesto excedido: ${budget.category}',
          'body':
              'Has gastado \$${spent.toStringAsFixed(2)} de \$${budget.limit.toStringAsFixed(2)}',
          'iconData': 0xe000,
          'color': 0xFFe63946,
          'overAmount': spent - budget.limit,
          'budgetId': budget.id,
        });
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, now.toIso8601String());
  }

  DateTime _calculateNextDueDate(RecurringExpense expense) {
    final now = DateTime.now();
    DateTime dueDate;

    switch (expense.frequency) {
      case 'Diario':
        dueDate = DateTime(now.year, now.month, now.day, 9, 0);
        if (dueDate.isBefore(now)) {
          dueDate = dueDate.add(const Duration(days: 1));
        }
        break;
      case 'Semanal':
        dueDate = DateTime(now.year, now.month, now.day, 9, 0);
        final daysUntilNext = (7 - now.weekday + expense.dayOfMonth % 7) % 7;
        dueDate =
            dueDate.add(Duration(days: daysUntilNext == 0 ? 7 : daysUntilNext));
        break;
      case 'Quincenal':
        final firstOfMonth =
            DateTime(now.year, now.month, expense.dayOfMonth.clamp(1, 15));
        final midOfMonth =
            DateTime(now.year, now.month, 15 + expense.dayOfMonth % 15);
        dueDate = now.day <= 15 ? firstOfMonth : midOfMonth;
        if (dueDate.isBefore(now)) {
          dueDate = dueDate.add(const Duration(days: 30));
        }
        break;
      case 'Mensual':
        dueDate = DateTime(
            now.year, now.month, expense.dayOfMonth.clamp(1, 28), 9, 0);
        if (dueDate.isBefore(now)) {
          dueDate = DateTime(
              now.month == 12 ? now.year + 1 : now.year,
              now.month == 12 ? 1 : now.month + 1,
              expense.dayOfMonth.clamp(1, 28),
              9,
              0);
        }
        break;
      case 'Anual':
        dueDate = DateTime(
            now.year, expense.startDate.month, expense.startDate.day, 9, 0);
        if (dueDate.isBefore(now)) {
          dueDate = DateTime(now.year + 1, expense.startDate.month,
              expense.startDate.day, 9, 0);
        }
        break;
      default:
        dueDate = DateTime(
            now.year, now.month, expense.dayOfMonth.clamp(1, 28), 9, 0);
    }

    return dueDate;
  }

  void dismissNotification(int index) {
    if (index >= 0 && index < _pendingNotifications.length) {
      _pendingNotifications.removeAt(index);
    }
  }

  void clearAllNotifications() {
    _pendingNotifications.clear();
  }

  Map<String, int> getNotificationSummary() {
    return {
      'total': _pendingNotifications.length,
      'recurring':
          _pendingNotifications.where((n) => n['type'] == 'recurring').length,
      'budgetWarning': _pendingNotifications
          .where((n) => n['type'] == 'budget_warning')
          .length,
      'budgetExceeded': _pendingNotifications
          .where((n) => n['type'] == 'budget_exceeded')
          .length,
    };
  }
}
