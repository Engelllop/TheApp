import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:intl/intl.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final AccountRepository _accountRepository = AccountRepository();
  List<Account> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await _accountRepository.getAccounts();
    setState(() {
      _accounts = accounts;
    });
  }

  Future<void> _makeTransfer() async {
    final amountController = TextEditingController();
    final descController = TextEditingController(text: 'Transferencia');
    String? fromAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
    String? toAccountId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
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
                const Text(
                  'Nueva Transferencia',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Desde',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: fromAccountId,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardBackground,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      items: _accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(
                                      account.color.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(account.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => fromAccountId = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Hacia',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: toAccountId,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardBackground,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      hint: const Text('Seleccionar cuenta',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      items: _accounts
                          .where((a) => a.id != fromAccountId)
                          .map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(
                                      account.color.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(account.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => toAccountId = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount > 0 &&
                          fromAccountId != null &&
                          toAccountId != null) {
                        await _transactionRepository.addTransaction(
                          description:
                              '${descController.text} (${_getAccountName(fromAccountId!)} → ${_getAccountName(toAccountId!)})',
                          amount: amount,
                          date: DateTime.now(),
                          isExpense: true,
                          accountId: fromAccountId!,
                        );
                        await _transactionRepository.addTransaction(
                          description:
                              '${descController.text} (${_getAccountName(toAccountId!)} ← ${_getAccountName(fromAccountId!)})',
                          amount: amount,
                          date: DateTime.now(),
                          isExpense: false,
                          accountId: toAccountId!,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transferencia realizada'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Transferir'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getAccountName(String accountId) {
    try {
      return _accounts.firstWhere((a) => a.id == accountId).name;
    } catch (e) {
      return 'Cuenta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferir'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz,
                    color: AppTheme.accentBlue, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transferir entre cuentas',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mueve dinero de una cuenta a otra\nde forma instantánea',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _makeTransfer,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Transferencia'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
