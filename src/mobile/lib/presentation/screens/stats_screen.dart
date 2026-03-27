import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Este Mes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _repository.getTransactions();
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  List<Transaction> get _filteredTransactions {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Esta Semana':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _transactions.where((t) => t.date.isAfter(weekStart)).toList();
      case 'Este Mes':
        return _transactions
            .where((t) => t.date.month == now.month && t.date.year == now.year)
            .toList();
      case 'Este Año':
        return _transactions.where((t) => t.date.year == now.year).toList();
      case 'Todo':
        return _transactions;
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
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
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildOverviewCards(),
                  const SizedBox(height: 20),
                  _buildExpensesVsIncome(),
                  const SizedBox(height: 20),
                  _buildTopCategories(),
                  const SizedBox(height: 20),
                  _buildDailyAverage(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Esta Semana', 'Este Mes', 'Este Año', 'Todo'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
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
                period,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.accentRed : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final transactions = _filteredTransactions;
    final totalExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;
    final count = transactions.length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Transacciones', count.toString(),
                AppTheme.accentBlue, Icons.receipt)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard('Gastos', _formatCurrency(totalExpenses),
                AppTheme.accentRed, Icons.arrow_downward)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard('Ingresos', _formatCurrency(totalIncome),
                AppTheme.accentGreen, Icons.arrow_upward)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesVsIncome() {
    final transactions = _filteredTransactions;
    final totalExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final total = totalExpenses + totalIncome;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Text('No hay datos para este período',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final expensePercent = total > 0 ? (totalExpenses / total * 100) : 0.0;
    final incomePercent = total > 0 ? (totalIncome / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GASTOS VS INGRESOS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: DonutPainter(
                          percentage: expensePercent / 100,
                          color: AppTheme.accentRed,
                        ),
                        child: Center(
                          child: Text(
                            '${expensePercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Gastos',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.compare_arrows,
                        color: AppTheme.textSecondary, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: DonutPainter(
                          percentage: incomePercent / 100,
                          color: AppTheme.accentGreen,
                        ),
                        child: Center(
                          child: Text(
                            '${incomePercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ingresos',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    final transactions =
        _filteredTransactions.where((t) => t.isExpense).toList();

    final categoryTotals = <String, double>{};
    for (final t in transactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Text('No hay gastos registrados',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP CATEGORÍAS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final percent = (category.value / total * 100);
            final color =
                AppTheme.chartColors[index % AppTheme.chartColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.key,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatCurrency(category.value)} (${percent.toStringAsFixed(0)}%)',
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: AppTheme.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailyAverage() {
    final transactions =
        _filteredTransactions.where((t) => t.isExpense).toList();
    if (transactions.isEmpty) return const SizedBox.shrink();

    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);

    DateTime? earliest;
    DateTime? latest;
    for (final t in transactions) {
      if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
      if (latest == null || t.date.isAfter(latest)) latest = t.date;
    }

    final days = earliest != null && latest != null
        ? latest.difference(earliest).inDays + 1
        : 30;
    final dailyAvg = days > 0 ? total / days : total;

    return Container(
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
              color: AppTheme.accentYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today,
                color: AppTheme.accentYellow, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROMEDIO DIARIO',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(dailyAvg),
                  style: const TextStyle(
                    color: AppTheme.accentYellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('En',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text('$days días',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final double percentage;
  final Color color;

  DonutPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = AppTheme.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = percentage * 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
