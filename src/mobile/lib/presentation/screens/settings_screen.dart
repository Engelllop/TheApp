import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/models/budget.dart';
import 'package:the_app/data/repositories/transaction_repository.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:the_app/data/repositories/budget_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionRepo.getTransactions();
      final accounts = await _accountRepo.getAccounts();
      final budgets = await _budgetRepo.getBudgets();

      final data = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar backup',
        fileName:
            'finanzas_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup exportado exitosamente'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _importData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Importar datos',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Esto reemplazará todos tus datos actuales. ¿Continuar?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        int importedTransactions = 0;
        int importedAccounts = 0;
        int importedBudgets = 0;

        if (data['transactions'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'transactions', jsonEncode(data['transactions']));
          importedTransactions = (data['transactions'] as List).length;
        }

        if (data['accounts'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accounts', jsonEncode(data['accounts']));
          importedAccounts = (data['accounts'] as List).length;
        }

        if (data['budgets'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('budgets', jsonEncode(data['budgets']));
          importedBudgets = (data['budgets'] as List).length;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Importado: $importedTransactions transacciones, $importedAccounts cuentas, $importedBudgets presupuestos'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Borrar todo',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los datos han sido eliminados'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  'DATOS',
                  [
                    _buildSettingItem(
                      icon: Icons.upload,
                      title: 'Exportar backup',
                      subtitle: 'Guarda tus datos en un archivo JSON',
                      onTap: _exportData,
                    ),
                    _buildSettingItem(
                      icon: Icons.download,
                      title: 'Importar backup',
                      subtitle: 'Restaura tus datos desde un archivo',
                      onTap: _importData,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'PELIGRO',
                  [
                    _buildSettingItem(
                      icon: Icons.delete_forever,
                      title: 'Borrar todos los datos',
                      subtitle: 'Elimina transacciones, cuentas y presupuestos',
                      onTap: _clearAllData,
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: AppTheme.accentRed, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Finanzas Personales',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Versión 1.0.0',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.accentRed : AppTheme.textPrimary;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDestructive ? AppTheme.accentRed : AppTheme.accentBlue)
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isDestructive ? AppTheme.accentRed : AppTheme.accentBlue,
            size: 20),
      ),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.chevron_right,
          color: isDestructive ? AppTheme.accentRed : AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
