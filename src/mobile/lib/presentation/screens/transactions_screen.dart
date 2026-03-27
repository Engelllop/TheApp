import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  final AccountRepository _accountRepository = AccountRepository();
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  String _filter = 'Todos';
  String? _selectedAccountId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _repository.getTransactions();
    final accounts = await _accountRepository.getAccounts();
    setState(() {
      _transactions = transactions;
      _accounts = accounts;
      _isLoading = false;
    });
  }

  List<Transaction> get _filteredTransactions {
    var filtered = _transactions;

    if (_filter == 'Gastos') {
      filtered = filtered.where((t) => t.isExpense).toList();
    } else if (_filter == 'Ingresos') {
      filtered = filtered.where((t) => !t.isExpense).toList();
    }

    if (_selectedAccountId != null) {
      filtered =
          filtered.where((t) => t.accountId == _selectedAccountId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> _exportToCsv() async {
    final transactions = _filteredTransactions;

    final rows = [
      ['Fecha', 'Descripción', 'Categoría', 'Monto', 'Tipo'],
      ...transactions.map((t) => [
            DateFormat('yyyy-MM-dd').format(t.date),
            t.description,
            t.category,
            t.amount.toString(),
            t.isExpense ? 'Gasto' : 'Ingreso',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar a CSV',
      fileName: 'transacciones_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exportado exitosamente'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    }
  }

  Future<void> _addTransaction() async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    String selectedAccount =
        _selectedAccountId ?? (_accounts.isNotEmpty ? _accounts.first.id : '1');

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
                  'Nueva Transacción',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAccount,
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
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAccount = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
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
                const SizedBox(height: 20),
                const Text(
                  'Tipo de transacción',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isExpense = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense
                                ? AppTheme.accentRed.withValues(alpha: 0.2)
                                : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isExpense
                                  ? AppTheme.accentRed
                                  : AppTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: isExpense
                                    ? AppTheme.accentRed
                                    : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gasto',
                                style: TextStyle(
                                  color: isExpense
                                      ? AppTheme.accentRed
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isExpense = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isExpense
                                ? AppTheme.accentGreen.withValues(alpha: 0.2)
                                : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isExpense
                                  ? AppTheme.accentGreen
                                  : AppTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: !isExpense
                                    ? AppTheme.accentGreen
                                    : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ingreso',
                                style: TextStyle(
                                  color: !isExpense
                                      ? AppTheme.accentGreen
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Agregar'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final amount = double.tryParse(amountController.text) ?? 0;
    if (descController.text.isNotEmpty && amount > 0) {
      await _repository.addTransaction(
        description: descController.text,
        amount: amount,
        date: DateTime.now(),
        isExpense: isExpense,
        accountId: selectedAccount,
      );
      _loadData();
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      int imported = 0;
      for (final row in rows.skip(1)) {
        if (row.length >= 2) {
          final description = row[0].toString();
          final amount = double.tryParse(row[1].toString()) ?? 0;
          if (description.isNotEmpty && amount > 0) {
            await _repository.addTransaction(
              description: description,
              amount: amount.abs(),
              date: DateTime.now(),
              isExpense: amount < 0,
              accountId: '1',
            );
            imported++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se importaron $imported transacciones')),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCsv,
            tooltip: 'Exportar CSV',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importCsv,
            tooltip: 'Importar CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty) _buildSearchBar(),
          _buildFilterChips(),
          if (_selectedAccountId != null) _buildAccountFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentRed),
                  )
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: AppTheme.accentRed,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title:
            const Text('Buscar', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textPrimary),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar por descripción o categoría',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardBackground,
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Buscando: "$_searchQuery"',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
            }),
            child: const Icon(Icons.close,
                color: AppTheme.textSecondary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountFilter() {
    final account =
        _accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (account != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(account.color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    account.name,
                    style: const TextStyle(
                        color: AppTheme.accentBlue, fontSize: 12),
                  ),
                ],
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedAccountId = null),
                  child: const Icon(Icons.close,
                      color: AppTheme.accentBlue, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Cuentas',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _accounts.length,
            itemBuilder: (context, index) {
              final account = _accounts[index];
              final accountColor =
                  Color(int.parse(account.color.replaceFirst('#', '0xFF')));
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accountColor,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(account.name,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(account.type,
                    style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos'),
          const SizedBox(width: 8),
          _buildFilterChip('Gastos'),
          const SizedBox(width: 8),
          _buildFilterChip('Ingresos'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentRed.withValues(alpha: 0.2)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentRed : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentRed : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay transacciones',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar CSV'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final t = _filteredTransactions[index];
        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentRed,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await _repository.deleteTransaction(t.id);
            _loadData();
          },
          child: _buildTransactionCard(t),
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction t) {
    final isExpense = t.isExpense;
    final color = isExpense ? AppTheme.accentRed : AppTheme.accentGreen;

    Account? account;
    try {
      account = _accounts.firstWhere((a) => a.id == t.accountId);
    } catch (e) {
      account = _accounts.isNotEmpty ? _accounts.first : null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(t.category),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (account != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                              account.color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      t.category,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}\$${t.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        return Icons.attach_money;
    }
  }
}
