import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/presentation/screens/settings_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repository = TransactionRepository();
  final AccountRepository _accountRepository = AccountRepository();
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  Map<String, double> _accountBalances = {};
  double _monthlyIncome = 0;
  double _monthlyExpenses = 0;
  double _totalBalance = 0;
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final transactions = await _repository.getTransactions();
    final accounts = await _accountRepository.getAccounts();
    final balances = await _repository.getBalancesByAccount();
    final now = DateTime.now();

    final monthlyTransactions = transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .toList();

    double income = 0;
    double expenses = 0;
    Map<String, double> categoryTotals = {};

    for (final t in monthlyTransactions) {
      if (t.isExpense) {
        expenses += t.amount;
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      } else {
        income += t.amount;
      }
    }

    double totalBalance = 0;
    for (final account in accounts) {
      totalBalance += balances[account.id] ?? 0;
    }

    setState(() {
      _transactions = transactions;
      _accounts = accounts;
      _accountBalances = balances;
      _totalBalance = totalBalance;
      _monthlyIncome = income;
      _monthlyExpenses = expenses;
      _categoryTotals = categoryTotals;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.accentRed,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildAccountsSection(),
                        const SizedBox(height: 20),
                        _buildMetricsRow(),
                        const SizedBox(height: 20),
                        _buildCategoryChart(),
                        const SizedBox(height: 20),
                        _buildRecentTransactions(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now).toUpperCase();

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'PANEL FINANCIERO',
                    style: TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text('Finanzas'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildAccountsSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CUENTAS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Total: ${_formatCurrency(_totalBalance)}',
                style: TextStyle(
                  color: _totalBalance >= 0
                      ? AppTheme.accentGreen
                      : AppTheme.accentRed,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final balance = _accountBalances[account.id] ?? 0;
                final accountColor =
                    Color(int.parse(account.color.replaceFirst('#', '0xFF')));

                return Container(
                  width: 140,
                  margin: EdgeInsets.only(
                      right: index < _accounts.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: accountColor, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accountColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCurrency(balance),
                          style: TextStyle(
                            color: balance >= 0
                                ? accountColor
                                : AppTheme.accentRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        account.type,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final balance = _monthlyIncome - _monthlyExpenses;

    return Row(
      children: [
        Expanded(
            child: _buildMetricCard('Ingresos', _monthlyIncome,
                AppTheme.accentGreen, Icons.arrow_upward)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildMetricCard('Gastos', _monthlyExpenses,
                AppTheme.accentRed, Icons.arrow_downward)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildMetricCard(
                'Balance',
                balance,
                balance >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                balance >= 0 ? Icons.trending_up : Icons.trending_down)),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, double value, Color color, IconData icon) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(value),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categoryTotals.isEmpty) {
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
              Icon(Icons.pie_chart_outline,
                  color: AppTheme.textSecondary, size: 48),
              SizedBox(height: 12),
              Text(
                'No hay gastos este mes',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'GASTOS POR CATEGORÍA',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryList(sortedCategories),
          const SizedBox(height: 16),
          _buildSimplePieChart(sortedCategories),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<MapEntry<String, double>> categories) {
    final total = categories.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: categories.take(5).map((entry) {
        final percentage = (entry.value / total * 100).clamp(0, 100);
        final colorIndex =
            categories.indexOf(entry) % AppTheme.chartColors.length;
        final color = AppTheme.chartColors[colorIndex];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                  ),
                  Text(
                    '${_formatCurrency(entry.value)} (${percentage.toStringAsFixed(0)}%)',
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
                  value: percentage / 100,
                  backgroundColor: AppTheme.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSimplePieChart(List<MapEntry<String, double>> categories) {
    final total = _categoryTotals.values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: SimplePieChartPainter(
                categories.map((e) {
                  final colorIndex =
                      categories.indexOf(e) % AppTheme.chartColors.length;
                  return PieSlice(
                    value: e.value / total,
                    color: AppTheme.chartColors[colorIndex],
                  );
                }).toList(),
                const Color(0xFF1a1a2e),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  categories.take(5).toList().asMap().entries.map((entry) {
                final colorIndex = entry.key % AppTheme.chartColors.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.chartColors[colorIndex],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          entry.value.key,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTx = _transactions.take(10).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ÚLTIMAS TRANSACCIONES',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${_transactions.length} total',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentTx.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay transacciones aún',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...recentTx.map((t) => _buildTransactionItem(t)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    final isExpense = t.isExpense;
    final color = isExpense ? AppTheme.accentRed : AppTheme.accentGreen;

    Account? account;
    try {
      account = _accounts.firstWhere((a) => a.id == t.accountId);
    } catch (e) {
      account = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (account != null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                              account.color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      t.category,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PieSlice {
  final double value;
  final Color color;
  PieSlice({required this.value, required this.color});
}

class SimplePieChartPainter extends CustomPainter {
  final List<PieSlice> slices;
  final Color holeColor;
  SimplePieChartPainter(this.slices, this.holeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -3.14159 / 2;

    for (final slice in slices) {
      final sweepAngle = slice.value * 2 * 3.14159;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
