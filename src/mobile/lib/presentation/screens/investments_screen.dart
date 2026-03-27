import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_app/core/theme.dart';
import 'package:intl/intl.dart';

class Investment {
  final String id;
  final String name;
  final String type;
  final double amount;
  final double currentValue;
  final double expectedReturn;
  final DateTime purchaseDate;
  final String color;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.currentValue,
    required this.expectedReturn,
    required this.purchaseDate,
    required this.color,
  });

  double get profit => currentValue - amount;
  double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  bool get isPositive => profit >= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'amount': amount,
        'currentValue': currentValue,
        'expectedReturn': expectedReturn,
        'purchaseDate': purchaseDate.toIso8601String(),
        'color': color,
      };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        expectedReturn: (json['expectedReturn'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchaseDate']),
        color: json['color'],
      );

  Investment copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    double? currentValue,
    double? expectedReturn,
    DateTime? purchaseDate,
    String? color,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      color: color ?? this.color,
    );
  }
}

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  static const String _key = 'investments';
  List<Investment> _investments = [];
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
      _investments = jsonList.map((json) => Investment.fromJson(json)).toList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_investments.map((i) => i.toJson()).toList());
    await prefs.setString(_key, data);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getInvestmentColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inversiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showInvestmentDialog(null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : _investments.isEmpty
              ? _buildEmptyState(isDark)
              : _buildInvestmentsList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: AppTheme.accentBlue),
          const SizedBox(height: 16),
          Text(
            'Sin inversiones',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para registrar una inversión',
            style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList(bool isDark) {
    final totalInvested =
        _investments.fold<double>(0, (sum, i) => sum + i.amount);
    final totalCurrent =
        _investments.fold<double>(0, (sum, i) => sum + i.currentValue);
    final totalProfit = totalCurrent - totalInvested;
    final profitPercentage =
        totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(
            totalInvested, totalCurrent, totalProfit, profitPercentage, isDark),
        const SizedBox(height: 20),
        Text(
          'MIS INVERSIONES',
          style: TextStyle(
            color:
                isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...(_investments.map((i) => _buildInvestmentCard(i, isDark))),
      ],
    );
  }

  Widget _buildSummaryCard(double invested, double current, double profit,
      double percent, bool isDark) {
    final isPositive = profit >= 0;

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
                  const Text('VALOR ACTUAL',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(current),
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
                  border: Border.all(
                      color: isPositive
                          ? AppTheme.accentGreen
                          : AppTheme.accentRed,
                      width: 6),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed,
                          size: 24),
                      Text('${percent.toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: isPositive
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  'Invertido', _formatCurrency(invested), AppTheme.textPrimary),
              _buildSummaryItem(
                'Ganancia/Pérdida',
                '${isPositive ? '+' : ''}${_formatCurrency(profit)}',
                isPositive ? AppTheme.accentGreen : AppTheme.accentRed,
              ),
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

  Widget _buildInvestmentCard(Investment inv, bool isDark) {
    final color = _getInvestmentColor(inv.color);

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
                  _getIconForType(inv.type),
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.name,
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.textPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text(inv.type,
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCurrency(inv.currentValue),
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(
                    '${inv.isPositive ? '+' : ''}${inv.profitPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: inv.isPositive
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed,
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invertido: ${_formatCurrency(inv.amount)}',
                  style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12)),
              Text('Rentabilidad: ${inv.expectedReturn.toStringAsFixed(1)}%',
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
                  onPressed: () => _showUpdateValueDialog(inv),
                  icon: const Icon(Icons.update, size: 16),
                  label: const Text('Actualizar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showInvestmentDialog(inv),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    size: 20, color: AppTheme.accentRed),
                onPressed: () => _deleteInvestment(inv),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Acciones':
        return Icons.show_chart;
      case 'Cripto':
        return Icons.currency_bitcoin;
      case 'Fondos':
        return Icons.pie_chart;
      case 'Bienes':
        return Icons.home;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showInvestmentDialog(Investment? existingInvestment) {
    final nameController =
        TextEditingController(text: existingInvestment?.name ?? '');
    final amountController = TextEditingController(
        text: existingInvestment?.amount.toString() ?? '');
    final currentController = TextEditingController(
        text: existingInvestment?.currentValue.toString() ?? '');
    final returnController = TextEditingController(
        text: existingInvestment?.expectedReturn.toString() ?? '0');
    String selectedType = existingInvestment?.type ?? 'Acciones';
    String selectedColor = existingInvestment?.color ?? '#457b9d';

    final colors = [
      {'code': '#e63946', 'name': 'Rojo'},
      {'code': '#457b9d', 'name': 'Azul'},
      {'code': '#2a9d8f', 'name': 'Verde'},
      {'code': '#e9c46a', 'name': 'Amarillo'},
      {'code': '#f4a261', 'name': 'Naranja'},
    ];

    final types = ['Acciones', 'Cripto', 'Fondos', 'Bienes', 'Otro'];

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
              Text(
                  existingInvestment == null
                      ? 'Nueva Inversión'
                      : 'Editar Inversión',
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
                              labelText: 'Monto invertido',
                              prefixIcon: Icon(Icons.attach_money)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: currentController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Valor actual',
                              prefixIcon: Icon(Icons.trending_up)))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: returnController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Rentabilidad esperada (%)',
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
                    final current =
                        double.tryParse(currentController.text) ?? amount;
                    final returns = double.tryParse(returnController.text) ?? 0;
                    if (name.isNotEmpty && amount > 0) {
                      final newInvestment = Investment(
                        id: existingInvestment?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        type: selectedType,
                        amount: amount,
                        currentValue: current,
                        expectedReturn: returns,
                        purchaseDate:
                            existingInvestment?.purchaseDate ?? DateTime.now(),
                        color: selectedColor,
                      );
                      setState(() {
                        if (existingInvestment != null) {
                          final index = _investments
                              .indexWhere((i) => i.id == existingInvestment.id);
                          if (index != -1) _investments[index] = newInvestment;
                        } else {
                          _investments.add(newInvestment);
                        }
                      });
                      _saveData();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(existingInvestment == null ? 'Crear' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateValueDialog(Investment inv) {
    final valueController =
        TextEditingController(text: inv.currentValue.toString());

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
            Text('Actualizar Valor - ${inv.name}',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: valueController,
              style: const TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Nuevo valor',
                  prefixIcon: Icon(Icons.attach_money)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final newValue = double.tryParse(valueController.text) ??
                          inv.currentValue;
                      if (newValue > 0) {
                        setState(() {
                          final index =
                              _investments.indexWhere((i) => i.id == inv.id);
                          if (index != -1) {
                            _investments[index] =
                                inv.copyWith(currentValue: newValue);
                          }
                        });
                        _saveData();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Actualizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteInvestment(Investment inv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inversión'),
        content: Text('¿Eliminar "${inv.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _investments.removeWhere((i) => i.id == inv.id));
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
