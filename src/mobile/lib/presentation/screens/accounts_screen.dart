import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/repositories/account_repository.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _repository = AccountRepository();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final accounts = await _repository.getAccounts();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getAccountColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAccountDialog(null),
          ),
        ],
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
                  _buildTotalCard(),
                  const SizedBox(height: 20),
                  _buildAccountsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'PATRIMONIO TOTAL',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$0.00',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat('Bancos', '\$0.00', AppTheme.accentBlue),
              const SizedBox(width: 24),
              _buildMiniStat('Efectivo', '\$0.00', AppTheme.accentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAccountsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MIS CUENTAS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (_accounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('No hay cuentas',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 8),
                  Text('Toca + para agregar',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...(_accounts.map((account) => _buildAccountCard(account))),
      ],
    );
  }

  Widget _buildAccountCard(Account account) {
    final color = _getAccountColor(account.color);

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Eliminar ', style: TextStyle(color: Colors.white)),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Eliminar cuenta',
                style: TextStyle(color: AppTheme.textPrimary)),
            content: Text('¿Eliminar ${account.name}?',
                style: const TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _repository.deleteAccount(account.id);
        _loadData();
      },
      child: GestureDetector(
        onTap: () => _showAccountDialog(account),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.type == 'Banco'
                      ? Icons.account_balance
                      : Icons.wallet,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.type,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountDialog(Account? existingAccount) {
    final nameController =
        TextEditingController(text: existingAccount?.name ?? '');
    String selectedType = existingAccount?.type ?? 'Banco';
    String selectedColor = existingAccount?.color ?? '#457b9d';

    final colors = [
      {'code': '#e63946', 'name': 'Rojo'},
      {'code': '#457b9d', 'name': 'Azul'},
      {'code': '#2a9d8f', 'name': 'Verde'},
      {'code': '#e9c46a', 'name': 'Amarillo'},
      {'code': '#f4a261', 'name': 'Naranja'},
      {'code': '#8ecae6', 'name': 'Celeste'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                existingAccount == null ? 'Nueva Cuenta' : 'Editar Cuenta',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tipo',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = 'Banco'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == 'Banco'
                              ? AppTheme.accentBlue.withValues(alpha: 0.2)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedType == 'Banco'
                                ? AppTheme.accentBlue
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance,
                                color: selectedType == 'Banco'
                                    ? AppTheme.accentBlue
                                    : AppTheme.textSecondary,
                                size: 18),
                            const SizedBox(width: 8),
                            Text('Banco',
                                style: TextStyle(
                                    color: selectedType == 'Banco'
                                        ? AppTheme.accentBlue
                                        : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedType = 'Efectivo'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == 'Efectivo'
                              ? AppTheme.accentGreen.withValues(alpha: 0.2)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedType == 'Efectivo'
                                ? AppTheme.accentGreen
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wallet,
                                color: selectedType == 'Efectivo'
                                    ? AppTheme.accentGreen
                                    : AppTheme.textSecondary,
                                size: 18),
                            const SizedBox(width: 8),
                            Text('Efectivo',
                                style: TextStyle(
                                    color: selectedType == 'Efectivo'
                                        ? AppTheme.accentGreen
                                        : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      if (existingAccount == null) {
                        await _repository.addAccount(Account(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          type: selectedType,
                          color: selectedColor,
                          initialBalance: 0,
                        ));
                      } else {
                        await _repository
                            .updateAccount(existingAccount.copyWith(
                          name: name,
                          type: selectedType,
                          color: selectedColor,
                        ));
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  child: Text(existingAccount == null ? 'Crear' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
