import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await _repository.getTransactions();
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _addTransaction() async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Transacción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Tipo:'),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Gasto'),
                    selected: isExpense,
                    onSelected: (v) => setDialogState(() => isExpense = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Ingreso'),
                    selected: !isExpense,
                    onSelected: (v) => setDialogState(() => isExpense = false),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? 0;
      if (descController.text.isNotEmpty && amount > 0) {
        await _repository.addTransaction(
          description: descController.text,
          amount: amount,
          date: DateTime.now(),
          isExpense: isExpense,
        );
        _loadTransactions();
      }
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
            );
            imported++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se importaron $imported transacciones')),
        );
        _loadTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importCsv,
            tooltip: 'Importar CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay transacciones'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _importCsv,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Importar CSV'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    return Dismissible(
                      key: Key(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await _repository.deleteTransaction(t.id);
                        _loadTransactions();
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.isExpense ? Colors.red[100] : Colors.green[100],
                            child: Icon(
                              _getCategoryIcon(t.category),
                              color: t.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(t.description),
                          subtitle: Text('${t.category} • ${_formatDate(t.date)}'),
                          trailing: Text(
                            '${t.isExpense ? '-' : '+'}\$${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: t.isExpense ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Comida': return Icons.restaurant;
      case 'Transporte': return Icons.directions_car;
      case 'Entretenimiento': return Icons.movie;
      case 'Compras': return Icons.shopping_bag;
      default: return Icons.attach_money;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
