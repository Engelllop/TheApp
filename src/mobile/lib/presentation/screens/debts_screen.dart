import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_app/core/theme.dart';
import 'package:intl/intl.dart';

class Debt {
  final String id;
  final String name;
  final String type;
  final double totalAmount;
  final double paidAmount;
  final double interestRate;
  final DateTime startDate;
  final DateTime? dueDate;
  final String color;

  Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.interestRate,
    required this.startDate,
    this.dueDate,
    required this.color,
  });

  double get remaining => totalAmount - paidAmount;
  double get progress =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  bool get completed => paidAmount >= totalAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'interestRate': interestRate,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'color': color,
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate']),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        color: json['color'],
      );

  Debt copyWith({
    String? id,
    String? name,
    String? type,
    double? totalAmount,
    double? paidAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    String? color,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
    );
  }
}

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  static const String _key = 'debts';
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _debts = jsonList.map((json) => Debt.fromJson(json)).toList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_debts.map((d) => d.toJson()).toList());
    await prefs.setString(_key, data);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getDebtColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.accentRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDebtDialog(null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : _debts.isEmpty
              ? _buildEmptyState(isDark)
              : _buildDebtsList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: AppTheme.accentGreen),
          const SizedBox(height: 16),
          Text(
            'Sin deudas',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para registrar una deuda',
            style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(bool isDark) {
    final totalDebt = _debts.fold<double>(0, (sum, d) => sum + d.totalAmount);
    final totalPaid = _debts.fold<double>(0, (sum, d) => sum + d.paidAmount);
    final totalRemaining =
        _debts.fold<double>(0, (sum, d) => sum + d.remaining);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(totalDebt, totalPaid, totalRemaining, isDark),
        const SizedBox(height: 20),
        Text(
          'MIS DEUDAS',
          style: TextStyle(
            color:
                isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...(_debts.map((d) => _buildDebtCard(d, isDark))),
      ],
    );
  }

  Widget _buildSummaryCard(
      double total, double paid, double remaining, bool isDark) {
    final progress = total > 0 ? paid / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DEUDA TOTAL',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(total),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentRed, width: 6),
                ),
                child: Center(
                  child: Text('${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.cardBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accentRed),
                minHeight: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Pagado', _formatCurrency(paid), AppTheme.accentGreen),
              _buildSummaryItem(
                  'Restante', _formatCurrency(remaining), AppTheme.accentRed),
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
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDebtCard(Debt debt, bool isDark) {
    final color = _getDebtColor(debt.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  debt.type == 'Tarjeta'
                      ? Icons.credit_card
                      : Icons.account_balance,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name,
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.textPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text(
                        '${debt.type} - ${debt.interestRate.toStringAsFixed(1)}% TEA',
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Text('${(debt.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: debt.progress,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatCurrency(debt.paidAmount),
                  style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12)),
              Text(_formatCurrency(debt.remaining),
                  style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(debt),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Pago'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showDebtDialog(debt),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    size: 20, color: AppTheme.accentRed),
                onPressed: () => _deleteDebt(debt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDebtDialog(Debt? existingDebt) {
    final nameController =
        TextEditingController(text: existingDebt?.name ?? '');
    final amountController =
        TextEditingController(text: existingDebt?.totalAmount.toString() ?? '');
    final paidController =
        TextEditingController(text: existingDebt?.paidAmount.toString() ?? '0');
    final rateController = TextEditingController(
        text: existingDebt?.interestRate.toString() ?? '0');
    String selectedType = existingDebt?.type ?? 'Tarjeta';
    String selectedColor = existingDebt?.color ?? '#e63946';

    final colors = [
      {'code': '#e63946', 'name': 'Rojo'},
      {'code': '#457b9d', 'name': 'Azul'},
      {'code': '#2a9d8f', 'name': 'Verde'},
      {'code': '#e9c46a', 'name': 'Amarillo'},
      {'code': '#f4a261', 'name': 'Naranja'},
    ];

    final types = ['Tarjeta', 'Préstamo', 'Hipoteca', 'Otro'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(existingDebt == null ? 'Nueva Deuda' : 'Editar Deuda',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Nombre', prefixIcon: Icon(Icons.label))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                dropdownColor: AppTheme.cardBackground,
                items: types
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style:
                                const TextStyle(color: AppTheme.textPrimary))))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: amountController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Monto total',
                              prefixIcon: Icon(Icons.attach_money)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: paidController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Pagado',
                              prefixIcon: Icon(Icons.paid)))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: rateController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Tasa (%) TEA',
                      prefixIcon: Icon(Icons.percent))),
              const SizedBox(height: 16),
              const Text('Color',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((c) {
                  final isSelected = selectedColor == c['code'];
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = c['code']!),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(
                            int.parse(c['code']!.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0;
                    final paid = double.tryParse(paidController.text) ?? 0;
                    final rate = double.tryParse(rateController.text) ?? 0;
                    if (name.isNotEmpty && amount > 0) {
                      final newDebt = Debt(
                        id: existingDebt?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        type: selectedType,
                        totalAmount: amount,
                        paidAmount: paid,
                        interestRate: rate,
                        startDate: existingDebt?.startDate ?? DateTime.now(),
                        color: selectedColor,
                      );
                      setState(() {
                        if (existingDebt != null) {
                          final index =
                              _debts.indexWhere((d) => d.id == existingDebt.id);
                          if (index != -1) _debts[index] = newDebt;
                        } else {
                          _debts.add(newDebt);
                        }
                      });
                      _saveData();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(existingDebt == null ? 'Crear' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(Debt debt) {
    final paymentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Registrar Pago - ${debt.name}',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: paymentController,
              style: const TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
                prefixIcon: const Icon(Icons.attach_money),
                hintText: 'Máximo: ${_formatCurrency(debt.remaining)}',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final payment =
                          double.tryParse(paymentController.text) ?? 0;
                      if (payment > 0 && payment <= debt.remaining) {
                        setState(() {
                          final index =
                              _debts.indexWhere((d) => d.id == debt.id);
                          if (index != -1) {
                            _debts[index] = debt.copyWith(
                                paidAmount: debt.paidAmount + payment);
                          }
                        });
                        _saveData();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deuda'),
        content: Text('¿Eliminar "${debt.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _debts.removeWhere((d) => d.id == debt.id));
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}
