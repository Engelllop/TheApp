import 'package:flutter/material.dart';
import 'package:the_app/core/theme.dart';
import 'package:the_app/data/models/goal.dart';
import 'package:the_app/data/repositories/goal_repository.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalRepository _repository = GoalRepository();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _goals = await _repository.getGoals();
    setState(() => _isLoading = false);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  Color _getGoalColor(String colorHex) {
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
        title: const Text('Metas de Ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showGoalDialog(null),
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
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildGoalsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    double totalTarget = _goals.fold(0, (sum, g) => sum + g.target);
    double totalCurrent = _goals.fold(0, (sum, g) => sum + g.current);
    final progress = totalTarget > 0 ? (totalCurrent / totalTarget) : 0.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROGRESO TOTAL',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGreen, width: 6),
                ),
                child: Center(
                  child: Icon(
                    progress >= 1.0 ? Icons.check : Icons.savings,
                    color: AppTheme.accentGreen,
                    size: 32,
                  ),
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
                  const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Ahorrado', _formatCurrency(totalCurrent),
                  AppTheme.accentGreen),
              _buildSummaryItem(
                  'Meta', _formatCurrency(totalTarget), AppTheme.textPrimary),
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

  Widget _buildGoalsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MIS METAS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (_goals.isEmpty)
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
                  Icon(Icons.flag_outlined,
                      size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('No hay metas',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 8),
                  Text('Toca + para crear una meta',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...(_goals.map((goal) => _buildGoalCard(goal))),
      ],
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final color = _getGoalColor(goal.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: goal.completed
            ? Border.all(color: AppTheme.accentGreen, width: 2)
            : null,
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
                  goal.completed ? Icons.check_circle : Icons.flag,
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
                      goal.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.completed
                          ? '¡Completada!'
                          : 'Faltan ${_formatCurrency(goal.remaining)}',
                      style: TextStyle(
                        color: goal.completed
                            ? AppTheme.accentGreen
                            : AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(goal.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: goal.completed ? AppTheme.accentGreen : color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.completed ? AppTheme.accentGreen : color,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(goal.current),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                _formatCurrency(goal.target),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(Goal? existingGoal) {
    final nameController =
        TextEditingController(text: existingGoal?.name ?? '');
    final targetController = TextEditingController(
      text: existingGoal?.target.toString() ?? '',
    );
    String selectedColor = existingGoal?.color ?? '#457b9d';

    final colors = [
      {'code': '#e63946', 'name': 'Rojo'},
      {'code': '#457b9d', 'name': 'Azul'},
      {'code': '#2a9d8f', 'name': 'Verde'},
      {'code': '#e9c46a', 'name': 'Amarillo'},
      {'code': '#f4a261', 'name': 'Naranja'},
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
                existingGoal == null ? 'Nueva Meta' : 'Editar Meta',
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
                  labelText: 'Nombre de la meta',
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  prefixIcon: Icon(Icons.attach_money),
                ),
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
                    final target = double.tryParse(targetController.text) ?? 0;
                    if (name.isNotEmpty && target > 0) {
                      final newGoal = Goal(
                        id: existingGoal?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        target: target,
                        current: existingGoal?.current ?? 0,
                        color: selectedColor,
                      );
                      if (existingGoal != null) {
                        await _repository.updateGoal(newGoal);
                      } else {
                        await _repository.addGoal(newGoal);
                      }
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  child: Text(existingGoal == null ? 'Crear' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
