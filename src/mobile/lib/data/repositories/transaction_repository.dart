import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionRepository {
  static const String _key = 'transactions';
  final AiService _aiService = AiService();

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<Transaction> addTransaction({
    required String description,
    required double amount,
    required DateTime date,
    required bool isExpense,
  }) async {
    final category = await _aiService.categorizeTransaction(description);
    
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      date: date,
      category: category,
      isExpense: isExpense,
    );

    final transactions = await getTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
    
    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }

  Future<double> getBalance() async {
    final transactions = await getTransactions();
    double balance = 0;
    for (final t in transactions) {
      if (t.isExpense) {
        balance -= t.amount;
      } else {
        balance += t.amount;
      }
    }
    return balance;
  }
}
