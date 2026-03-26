import 'package:flutter/material.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repository = TransactionRepository();
  double _balance = 0;
  double _monthlySpent = 0;
  List<Transaction> _recentTransactions = [];
  String _aiMessage = 'Cargando insights...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await _repository.getBalance();
    final transactions = await _repository.getTransactions();
    final now = DateTime.now();
    final monthlySpent = transactions
        .where((t) => t.isExpense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    final recent = transactions.take(5).toList();

    setState(() {
      _balance = balance;
      _monthlySpent = monthlySpent;
      _recentTransactions = recent;
      _aiMessage = _generateAiMessage(balance, monthlySpent);
    });
  }

  String _generateAiMessage(double balance, double spent) {
    if (spent > 1000) {
      return '⚠️ ¡Ojo! Este mes has gastado \$${spent.toStringAsFixed(2)} en gastos. Revisa tus categorías.';
    } else if (balance < 0) {
      return '🔴 Tu balance es negativo. Es hora de revisar tus gastos.';
    }
    return '✅ ¡Vas bien! Tu balance es positivo este mes.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildAiAdviceCard(),
              const SizedBox(height: 16),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: _balance >= 0 ? Colors.green : Colors.red,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Balance Actual',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdviceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asesor IA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_aiMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transacciones Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay transacciones aún')),
            ),
          )
        else
          ...(_recentTransactions.map((t) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.isExpense ? Colors.red[100] : Colors.green[100],
                child: Icon(
                  t.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: t.isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(t.description),
              subtitle: Text(t.category),
              trailing: Text(
                '${t.isExpense ? '-' : '+'}\$${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: t.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ))),
      ],
    );
  }
}
