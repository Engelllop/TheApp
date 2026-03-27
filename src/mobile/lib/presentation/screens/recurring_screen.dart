import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/recurring_expense.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/repositories/recurring_repository.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:intl/intl.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final RecurringRepository _repository = RecurringRepository();
  final AccountRepository _accountRepository = AccountRepository();
  List<RecurringExpense> _expenses = [];
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenses = await _repository.getRecurringExpenses();
    final accounts = await _accountRepository.getAccounts();
    setState(() {
      _expenses = expenses;
      _accounts = accounts;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getAccountColor(String? accountId) {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      return Color(int.parse(account.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.accentBlue;
    }
  }

  String _getAccountName(String? accountId) {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      return account.name;
    } catch (e) {
      return 'Cuenta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showExpenseDialog(null),
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
                  _buildExpensesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final activeExpenses = _expenses.where((e) => e.isActive).toList();
    final monthlyTotal = activeExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final yearlyTotal = monthlyTotal * 12;

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Gastos activos',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${activeExpenses.length}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 40, color: AppTheme.cardBorder),
              Column(
                children: [
                  const Text('Mensual',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(monthlyTotal),
                      style: const TextStyle(
                          color: AppTheme.accentYellow,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 40, color: AppTheme.cardBorder),
              Column(
                children: [
                  const Text('Anual',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(yearlyTotal),
                      style: const TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MIS GASTOS FIJOS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (_expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.repeat, size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('No hay gastos recurrentes',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 8),
                  Text('Toca + para agregar',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...(_expenses.map((expense) => _buildExpenseCard(expense))),
      ],
    );
  }

  Widget _buildExpenseCard(RecurringExpense expense) {
    final color = _getAccountColor(expense.accountId);

    return Dismissible(
      key: Key(expense.id),
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
      onDismissed: (_) async {
        await _repository.deleteRecurringExpense(expense.id);
        _loadData();
      },
      child: GestureDetector(
        onTap: () => _showExpenseDialog(expense),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (expense.isActive
                          ? AppTheme.accentGreen
                          : AppTheme.textSecondary)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.repeat,
                  color: expense.isActive
                      ? AppTheme.accentGreen
                      : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: expense.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getAccountName(expense.accountId),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(width: 8),
                        Text(
                          'Día ${expense.dayOfMonth}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(expense.amount),
                    style: TextStyle(
                      color: expense.isActive
                          ? AppTheme.accentRed
                          : AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      await _repository.updateRecurringExpense(
                        expense.copyWith(isActive: !expense.isActive),
                      );
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (expense.isActive
                                ? AppTheme.accentGreen
                                : AppTheme.textSecondary)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.isActive ? 'Activo' : 'Pausado',
                        style: TextStyle(
                          color: expense.isActive
                              ? AppTheme.accentGreen
                              : AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
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

  void _showExpenseDialog(RecurringExpense? existingExpense) {
    final nameController =
        TextEditingController(text: existingExpense?.name ?? '');
    final amountController = TextEditingController(
      text: existingExpense?.amount.toString() ?? '',
    );
    String selectedAccountId = existingExpense?.accountId ??
        (_accounts.isNotEmpty ? _accounts.first.id : '');
    int selectedDay = existingExpense?.dayOfMonth ?? 1;
    String selectedCategory = existingExpense?.category ?? 'Otros';
    String selectedFrequency = existingExpense?.frequency ?? 'Mensual';

    final categories = [
      'Comida',
      'Transporte',
      'Entretenimiento',
      'Compras',
      'Salud',
      'Servicios',
      'Otros'
    ];

    final frequencies = ['Diario', 'Semanal', 'Quincenal', 'Mensual', 'Anual'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
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
                existingExpense == null
                    ? 'Nuevo Gasto Recurrente'
                    : 'Editar Gasto Recurrente',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'ej: Netflix, Alquiler',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto mensual',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  prefixIcon: Icon(Icons.schedule),
                ),
                dropdownColor: AppTheme.cardBackground,
                items: frequencies
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f,
                              style:
                                  const TextStyle(color: AppTheme.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedFrequency = v!),
              ),
              const SizedBox(height: 16),
              const Text('Categoría',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentRed.withValues(alpha: 0.2)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.accentRed
                                : AppTheme.cardBorder),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              color: isSelected
                                  ? AppTheme.accentRed
                                  : AppTheme.textSecondary,
                              fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Día de cobro',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.remove, color: AppTheme.textSecondary),
                    onPressed: () => setDialogState(() =>
                        selectedDay = selectedDay > 1 ? selectedDay - 1 : 28),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Text(
                      'Día $selectedDay',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.textSecondary),
                    onPressed: () => setDialogState(() =>
                        selectedDay = selectedDay < 28 ? selectedDay + 1 : 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (name.isNotEmpty && amount > 0) {
                      final expense = RecurringExpense(
                        id: existingExpense?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        amount: amount,
                        category: selectedCategory,
                        accountId: selectedAccountId,
                        dayOfMonth: selectedDay,
                        isActive: existingExpense?.isActive ?? true,
                        frequency: selectedFrequency,
                      );
                      if (existingExpense == null) {
                        await _repository.addRecurringExpense(expense);
                      } else {
                        await _repository.updateRecurringExpense(expense);
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  child: Text(existingExpense == null ? 'Crear' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
