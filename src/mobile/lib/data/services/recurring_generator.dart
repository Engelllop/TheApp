import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_app/data/models/recurring_expense.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/recurring_repository.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/data/services/ai_service.dart';

class RecurringGenerator {
  final RecurringRepository _recurringRepo = RecurringRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AiService _aiService = AiService();

  static const String _lastRunKey = 'last_recurring_run';

  Future<void> generateRecurringTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getString(_lastRunKey);
    final today = DateTime.now();

    final recurringExpenses = await _recurringRepo.getRecurringExpenses();

    for (final expense in recurringExpenses) {
      if (!_shouldGenerate(expense, lastRun, today)) continue;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: expense.name,
        amount: expense.amount,
        date: today,
        category: expense.category,
        isExpense: true,
        accountId: expense.accountId,
      );

      await _transactionRepo.addTransaction(
        description: transaction.description,
        amount: transaction.amount,
        date: transaction.date,
        isExpense: transaction.isExpense,
        accountId: transaction.accountId,
      );
    }

    await prefs.setString(_lastRunKey, today.toIso8601String());
  }

  bool _shouldGenerate(
      RecurringExpense expense, String? lastRun, DateTime today) {
    if (!expense.isActive) return false;

    DateTime? nextDue = _calculateNextDue(
        expense, lastRun != null ? DateTime.parse(lastRun) : null);

    if (nextDue == null) return false;

    return nextDue.year == today.year &&
        nextDue.month == today.month &&
        nextDue.day <= today.day;
  }

  DateTime? _calculateNextDue(RecurringExpense expense, DateTime? lastRun) {
    final baseDate = expense.startDate;
    final now = DateTime.now();
    DateTime nextDue;

    switch (expense.frequency) {
      case 'Diario':
        nextDue = baseDate;
        while (nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) {
          nextDue = nextDue.add(const Duration(days: 1));
        }
        break;
      case 'Semanal':
        nextDue = baseDate;
        while (nextDue.isBefore(now)) {
          nextDue = nextDue.add(const Duration(days: 7));
        }
        break;
      case 'Quincenal':
        nextDue = DateTime(baseDate.year, baseDate.month, 1);
        while (nextDue.isBefore(now)) {
          if (baseDate.day > 15) {
            nextDue = DateTime(
                nextDue.month == 12 ? nextDue.year + 1 : nextDue.year,
                nextDue.month == 12 ? 1 : nextDue.month + 1,
                15);
          } else {
            nextDue = DateTime(
                nextDue.month == 12 ? nextDue.year + 1 : nextDue.year,
                nextDue.month == 12 ? 1 : nextDue.month + 1,
                1);
          }
        }
        break;
      case 'Mensual':
        nextDue = DateTime(now.year, now.month, baseDate.day.clamp(1, 28));
        if (nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) {
          nextDue = DateTime(now.month == 12 ? now.year + 1 : now.year,
              now.month == 12 ? 1 : now.month + 1, baseDate.day.clamp(1, 28));
        }
        break;
      case 'Anual':
        nextDue = DateTime(now.year, baseDate.month, baseDate.day);
        if (nextDue.isBefore(now)) {
          nextDue = DateTime(now.year + 1, baseDate.month, baseDate.day);
        }
        break;
      default:
        return null;
    }

    return nextDue;
  }

  Future<int> checkUpcomingRecurring() async {
    final expenses = await _recurringRepo.getRecurringExpenses();
    final now = DateTime.now();
    int count = 0;

    for (final expense in expenses) {
      if (!expense.isActive) continue;

      final nextDue = _calculateNextDue(expense, now);
      if (nextDue == null) continue;

      final daysUntilDue = nextDue.difference(now).inDays;
      if (daysUntilDue <= 3) {
        count++;
      }
    }

    return count;
  }
}
