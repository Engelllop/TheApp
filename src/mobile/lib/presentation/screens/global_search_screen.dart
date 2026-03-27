import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/models/budget.dart';
import 'package:the_app/data/models/goal.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:the_app/data/repositories/budget_repository.dart';
import 'package:the_app/data/repositories/goal_repository.dart';
import 'package:intl/intl.dart';

class GlobalSearchScreen extends StatefulWidget {
  final Function(int, dynamic)? onItemSelected;

  const GlobalSearchScreen({super.key, this.onItemSelected});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();
  final GoalRepository _goalRepo = GoalRepository();

  List<dynamic> _results = [];
  String _query = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _query = '';
      });
      return;
    }

    if (query.length >= 2) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    _query = query;

    final List<dynamic> allResults = [];

    final transactions = await _transactionRepo.getTransactions();
    final accounts = await _accountRepo.getAccounts();
    final budgets = await _budgetRepo.getBudgets();
    final goals = await _goalRepo.getGoals();

    allResults.addAll(transactions
        .where((t) =>
            t.description.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query))
        .map((t) => _SearchResult(
              type: 'transaction',
              title: t.description,
              subtitle:
                  '${t.isExpense ? 'Gasto' : 'Ingreso'} - \$${t.amount.toStringAsFixed(2)}',
              data: t,
              icon: t.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: t.isExpense ? AppTheme.accentRed : AppTheme.accentGreen,
            )));

    allResults.addAll(accounts
        .where((a) =>
            a.name.toLowerCase().contains(query) ||
            a.type.toLowerCase().contains(query))
        .map((a) => _SearchResult(
              type: 'account',
              title: a.name,
              subtitle: a.type,
              data: a,
              icon: Icons.account_balance,
              color: AppTheme.accentBlue,
            )));

    allResults.addAll(budgets
        .where((b) => b.category.toLowerCase().contains(query))
        .map((b) => _SearchResult(
              type: 'budget',
              title: b.category,
              subtitle: 'Presupuesto: \$${b.limit.toStringAsFixed(2)}',
              data: b,
              icon: Icons.account_balance_wallet,
              color: AppTheme.accentYellow,
            )));

    allResults.addAll(goals
        .where((g) => g.name.toLowerCase().contains(query))
        .map((g) => _SearchResult(
              type: 'goal',
              title: g.name,
              subtitle:
                  'Meta: \$${g.target.toStringAsFixed(2)} - ${(g.progress * 100).toStringAsFixed(0)}%',
              data: g,
              icon: Icons.flag,
              color: AppTheme.accentGreen,
            )));

    setState(() {
      _results = allResults;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar transacciones, cuentas...',
            hintStyle: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
            ),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentRed),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para "$_query"',
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final groupedResults = <String, List<_SearchResult>>{};
    for (final result in _results.cast<_SearchResult>()) {
      groupedResults.putIfAbsent(result.type, () => []).add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final type = groupedResults.keys.elementAt(index);
        final items = groupedResults[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTypeName(type),
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((result) => _buildResultTile(result, isDark)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'transaction':
        return 'TRANSACCIONES';
      case 'account':
        return 'CUENTAS';
      case 'budget':
        return 'PRESUPUESTOS';
      case 'goal':
        return 'METAS';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildResultTile(_SearchResult result, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: result.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(result.icon, color: result.color, size: 20),
        ),
        title: Text(
          result.title,
          style: TextStyle(
            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          result.subtitle,
          style: TextStyle(
            color:
                isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
        ),
        onTap: () {
          if (widget.onItemSelected != null) {
            widget.onItemSelected!(0, result.data);
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _SearchResult {
  final String type;
  final String title;
  final String subtitle;
  final dynamic data;
  final IconData icon;
  final Color color;

  _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.icon,
    required this.color,
  });
}
