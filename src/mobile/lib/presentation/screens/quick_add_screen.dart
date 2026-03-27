import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/data/repositories/account_repository.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();

  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  String _selectedCategory = 'Alimentos';
  String _selectedAccountId = '';
  List<Account> _accounts = [];
  bool _isLoading = false;

  final List<String> _expenseCategories = [
    'Alimentos',
    'Transporte',
    'Servicios',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Shopping',
    'Hogar',
    'Otros',
  ];

  final List<String> _incomeCategories = [
    'Salario',
    'Freelance',
    'Inversión',
    'Regalo',
    'Reembolso',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    _accounts = await _accountRepo.getAccounts();
    if (_accounts.isNotEmpty) {
      _selectedAccountId = _accounts.first.id;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (desc.isEmpty || amount <= 0 || _selectedAccountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _transactionRepo.addTransaction(
      description: desc,
      amount: amount,
      date: DateTime.now(),
      isExpense: _isExpense,
      accountId: _selectedAccountId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isExpense ? 'Gasto registrado' : 'Ingreso registrado'),
          backgroundColor:
              _isExpense ? AppTheme.accentRed : AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _isExpense ? _expenseCategories : _incomeCategories;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Gasto',
                      Icons.arrow_upward,
                      !_isExpense,
                      AppTheme.accentRed,
                      () => setState(() {
                        _isExpense = false;
                        _selectedCategory = _incomeCategories.first;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleButton(
                      'Ingreso',
                      Icons.arrow_downward,
                      _isExpense,
                      AppTheme.accentGreen,
                      () => setState(() {
                        _isExpense = true;
                        _selectedCategory = _expenseCategories.first;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descController,
                style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.edit),
                  hintText: _isExpense ? 'Ej: Almuerzo' : 'Ej: Pago cliente',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                dropdownColor: isDark
                    ? AppTheme.cardBackground
                    : AppTheme.lightCardBackground,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAccountId.isEmpty ? null : _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Cuenta',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                dropdownColor: isDark
                    ? AppTheme.cardBackground
                    : AppTheme.lightCardBackground,
                items: _accounts
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v ?? ''),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveTransaction,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_isExpense ? Icons.remove : Icons.add),
                  label: Text(
                      _isExpense ? 'Registrar Gasto' : 'Registrar Ingreso'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isExpense ? AppTheme.accentRed : AppTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
