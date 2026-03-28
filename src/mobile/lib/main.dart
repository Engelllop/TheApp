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

  final List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        screen: const DashboardScreen()),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Movimientos',
        screen: const TransactionsScreen()),
    _NavItem(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'Presupuestos',
        screen: const BudgetScreen()),
    _NavItem(
        icon: Icons.repeat_outlined,
        selectedIcon: Icons.repeat,
        label: 'Recurrentes',
        screen: const RecurringScreen()),
    _NavItem(
        icon: Icons.account_balance_outlined,
        selectedIcon: Icons.account_balance,
        label: 'Cuentas',
        screen: const AccountsScreen()),
    _NavItem(
        icon: Icons.swap_horiz_outlined,
        selectedIcon: Icons.swap_horiz,
        label: 'Transferir',
        screen: const TransferScreen()),
    _NavItem(
        icon: Icons.flag_outlined,
        selectedIcon: Icons.flag,
        label: 'Metas',
        screen: const GoalsScreen()),
    _NavItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: 'Calendario',
        screen: const CalendarScreen()),
    _NavItem(
        icon: Icons.credit_card_outlined,
        selectedIcon: Icons.credit_card,
        label: 'Deudas',
        screen: const DebtsScreen()),
    _NavItem(
        icon: Icons.trending_up_outlined,
        selectedIcon: Icons.trending_up,
        label: 'Inversiones',
        screen: const InvestmentsScreen()),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'Estadísticas',
        screen: const StatsScreen()),
    _NavItem(
        icon: Icons.smart_toy_outlined,
        selectedIcon: Icons.smart_toy,
        label: 'Asistente IA',
        screen: const AiAdvisorScreen()),
  ];

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddScreen(),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final useDrawer = screenWidth < 800;

    if (useDrawer) {
      return _buildDrawerLayout(isDark);
    } else {
      return _buildRailLayout(isDark);
    }
  }

  Widget _buildDrawerLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        backgroundColor:
            isDark ? AppTheme.background : AppTheme.lightBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      drawer: _buildDrawer(isDark),
      body: _navItems[_selectedIndex].screen,
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAdd,
        backgroundColor: AppTheme.accentRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor:
          isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                    : [Colors.white, Colors.grey[100]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: AppTheme.accentRed, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'Finanzas',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tu asistente financiero',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;

                return ListTile(
                  leading: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected
                        ? AppTheme.accentRed
                        : (isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.accentRed
                          : (isDark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.accentRed.withValues(alpha: 0.1),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings,
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary),
            title: Text('Configuración',
                style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              _openSettings();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRailLayout(bool isDark) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 220,
            backgroundColor:
                isDark ? AppTheme.cardBackground : AppTheme.lightCardBackground,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: AppTheme.accentRed, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Finanzas',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: Icon(Icons.settings,
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary),
                    onPressed: _openSettings,
                  ),
                ),
              ),
            ),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon,
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
                selectedIcon:
                    Icon(item.selectedIcon, color: AppTheme.accentRed),
                label: Text(
                  item.label,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.background : AppTheme.lightBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppTheme.cardBorder
                            : AppTheme.lightCardBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _navItems[_selectedIndex].label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      FloatingActionButton.small(
                        onPressed: _showQuickAdd,
                        backgroundColor: AppTheme.accentRed,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _navItems[_selectedIndex].screen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}
