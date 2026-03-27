import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/presentation/screens/dashboard_screen.dart';
import 'package:the_app/presentation/screens/transactions_screen.dart';
import 'package:the_app/presentation/screens/budget_screen.dart';
import 'package:the_app/presentation/screens/accounts_screen.dart';
import 'package:the_app/presentation/screens/goals_screen.dart';
import 'package:the_app/presentation/screens/stats_screen.dart';
import 'package:the_app/presentation/screens/ai_advisor_screen.dart';
import 'package:the_app/presentation/screens/recurring_screen.dart';
import 'package:the_app/presentation/screens/transfer_screen.dart';

void main() {
  runApp(const TheApp());
}

class TheApp extends StatelessWidget {
  const TheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas Personales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
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
    const AiAdvisorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.accentRed),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppTheme.accentRed),
              label: 'Movimientos',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon:
                  Icon(Icons.account_balance_wallet, color: AppTheme.accentRed),
              label: 'Presupuestos',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_outlined),
              selectedIcon: Icon(Icons.repeat, color: AppTheme.accentRed),
              label: 'Recurrentes',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon:
                  Icon(Icons.account_balance, color: AppTheme.accentRed),
              label: 'Cuentas',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz, color: AppTheme.accentRed),
              label: 'Transferir',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag, color: AppTheme.accentRed),
              label: 'Metas',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppTheme.accentRed),
              label: 'Estadísticas',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy, color: AppTheme.accentRed),
              label: 'IA',
            ),
          ],
        ),
      ),
    );
  }
}
