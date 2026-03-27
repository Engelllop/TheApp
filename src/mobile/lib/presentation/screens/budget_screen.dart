import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/budget.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/budget_repository.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetRepository _budgetRepository = BudgetRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  List<Budget> _budgets = [];
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final budgets = await _budgetRepository.getBudgets();
    final transactions = await _transactionRepository.getTransactions();
    final now = DateTime.now();

    final monthlyExpenses = transactions.where((t) =>
        t.isExpense && t.date.month == now.month && t.date.year == now.year);

    final spending = <String, double>{};
    for (final t in monthlyExpenses) {
      spending[t.category] = (spending[t.category] ?? 0) + t.amount;
    }

    setState(() {
      _budgets = budgets;
      _categorySpending = spending;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getBudgetColor(double percentage) {
    if (percentage >= 100) return AppTheme.accentRed;
    if (percentage >= 80) return AppTheme.accentYellow;
    return AppTheme.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.accentRed,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildBudgetList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    double totalBudget = _budgets.fold(0, (sum, b) => sum + b.limit);
    double totalSpent = 0;

    for (final budget in _budgets) {
      totalSpent += _categorySpending[budget.category] ?? 0;
    }

    final percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final remaining = totalBudget - totalSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRESUPUESTO TOTAL',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(totalBudget),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBudgetColor(percentage).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _getBudgetColor(percentage),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.cardBorder,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getBudgetColor(percentage)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Gastado', _formatCurrency(totalSpent), AppTheme.accentRed),
              _buildSummaryItem(
                  'Restante', _formatCurrency(remaining), AppTheme.accentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetList() {
    if (_budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'No hay presupuestos',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POR CATEGORÍA',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...(_budgets.map((budget) => _buildBudgetCard(budget))),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _categorySpending[budget.category] ?? 0;
    final percentage = budget.limit > 0 ? (spent / budget.limit * 100) : 0.0;
    final remaining = budget.limit - spent;
    final budgetColor =
        Color(int.parse(budget.color.replaceFirst('#', '0xFF')));

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Eliminar ', style: TextStyle(color: Colors.white)),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Eliminar presupuesto',
                style: TextStyle(color: AppTheme.textPrimary)),
            content: Text('¿Eliminar presupuesto de ${budget.category}?',
                style: const TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _budgetRepository.deleteBudget(budget.id);
        _loadData();
      },
      child: GestureDetector(
        onTap: () => _showEditBudgetDialog(budget),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: budgetColor, width: 4),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: budgetColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(budget.category),
                          color: budgetColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        budget.category,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getBudgetColor(percentage),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (percentage >= 100)
                        const Text(
                          '¡Límite excedido!',
                          style: TextStyle(
                            color: AppTheme.accentRed,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getBudgetColor(percentage)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatCurrency(spent)} gastado',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Límite: ${_formatCurrency(budget.limit)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Comida':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Salud':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  void _showAddBudgetDialog() {
    _showBudgetDialog(null);
  }

  void _showEditBudgetDialog(Budget budget) {
    _showBudgetDialog(budget);
  }

  void _showBudgetDialog(Budget? existingBudget) {
    final nameController =
        TextEditingController(text: existingBudget?.category ?? '');
    final limitController = TextEditingController(
      text: existingBudget?.limit.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              existingBudget == null
                  ? 'Nuevo Presupuesto'
                  : 'Editar Presupuesto',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limitController,
              style: const TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Límite mensual',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final limit = double.tryParse(limitController.text) ?? 0;

                  if (name.isNotEmpty && limit > 0.0) {
                    if (existingBudget == null) {
                      await _budgetRepository.addBudget(Budget(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        category: name,
                        limit: limit,
                        color: '#457b9d',
                      ));
                    } else {
                      await _budgetRepository
                          .updateBudget(existingBudget.copyWith(
                        category: name,
                        limit: limit,
                      ));
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  }
                },
                child: Text(existingBudget == null ? 'Crear' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
