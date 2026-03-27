import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/services/theme_service.dart';
import 'package:the_app/presentation/screens/dashboard_screen.dart';
import 'package:the_app/presentation/screens/transactions_screen.dart';
import 'package:the_app/presentation/screens/budget_screen.dart';
import 'package:the_app/presentation/screens/accounts_screen.dart';
import 'package:the_app/presentation/screens/goals_screen.dart';
import 'package:the_app/presentation/screens/stats_screen.dart';
import 'package:the_app/presentation/screens/ai_advisor_screen.dart';
import 'package:the_app/presentation/screens/recurring_screen.dart';
import 'package:the_app/presentation/screens/transfer_screen.dart';
import 'package:the_app/presentation/screens/calendar_screen.dart';
import 'package:the_app/presentation/screens/debts_screen.dart';
import 'package:the_app/presentation/screens/investments_screen.dart';
import 'package:the_app/presentation/screens/settings_screen.dart';
import 'package:the_app/presentation/screens/quick_add_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const TheApp(),
    ),
  );
}

class TheApp extends StatelessWidget {
  const TheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          title: 'Finanzas Personales',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const BudgetScreen(),
    const RecurringScreen(),
    const AccountsScreen(),
    const TransferScreen(),
    const GoalsScreen(),
    const StatsScreen(),
    const CalendarScreen(),
    const DebtsScreen(),
    const InvestmentsScreen(),
    const AiAdvisorScreen(),
  ];

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAdd,
        backgroundColor: AppTheme.accentRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (index == 11) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              return;
            }
            setState(() => _selectedIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.accentRed),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppTheme.accentRed),
              label: 'Movimientos',
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon:
                  Icon(Icons.account_balance_wallet, color: AppTheme.accentRed),
              label: 'Presupuestos',
            ),
            NavigationDestination(
              icon: const Icon(Icons.repeat_outlined),
              selectedIcon: Icon(Icons.repeat, color: AppTheme.accentRed),
              label: 'Recurrentes',
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_outlined),
              selectedIcon:
                  Icon(Icons.account_balance, color: AppTheme.accentRed),
              label: 'Cuentas',
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz, color: AppTheme.accentRed),
              label: 'Transferir',
            ),
            NavigationDestination(
              icon: const Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag, color: AppTheme.accentRed),
              label: 'Metas',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppTheme.accentRed),
              label: 'Estadísticas',
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppTheme.accentRed),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: const Icon(Icons.credit_card_outlined),
              selectedIcon: Icon(Icons.credit_card, color: AppTheme.accentRed),
              label: 'Deudas',
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up, color: AppTheme.accentRed),
              label: 'Inversiones',
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy, color: AppTheme.accentRed),
              label: 'IA',
            ),
          ].take(12).toList(),
        ),
      ),
    );
  }
}
