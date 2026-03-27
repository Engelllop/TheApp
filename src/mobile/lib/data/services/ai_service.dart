import '../models/transaction.dart';
import '../models/budget.dart';

class AiService {
  Future<Map<String, dynamic>> getFinancialInsights(
    List<Transaction> transactions,
    List<Budget> budgets,
  ) async {
    final totalExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final categoryTotals = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    String topCategory = '';
    double topAmount = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topAmount) {
        topAmount = entry.value;
        topCategory = entry.key;
      }
    }

    final balance = totalIncome - totalExpenses;
    String resumen;
    String? alerta;
    List<String> consejos = [];

    if (balance < 0) {
      resumen = 'Tu balance es negativo: -\$${balance.abs().toStringAsFixed(2)}. Estás gastando más de lo que ganas.';
      alerta = '¡Alerta! Tus gastos superan tus ingresos.';
    } else {
      resumen = 'Tu balance es positivo: \$${balance.toStringAsFixed(2)}. '
          'Gastaste \$${totalExpenses.toStringAsFixed(2)} e ingresaste \$${totalIncome.toStringAsFixed(2)}.';
    }

    if (topAmount > 0) {
      consejos.add('Tu mayor gasto es en $topCategory: \$${topAmount.toStringAsFixed(2)}');
    }

    if (totalExpenses > 0) {
      final avgDaily = totalExpenses / 30;
      consejos.add('Promedio de gasto diario: \$${avgDaily.toStringAsFixed(2)}');
    }

    if (balance > 0) {
      final savingsRate = (balance / totalIncome * 100);
      if (savingsRate >= 20) {
        consejos.add('¡Excelente! Estás ahorrando el ${savingsRate.toStringAsFixed(0)}% de tus ingresos.');
      } else {
        consejos.add('Intenta ahorrar al menos el 20% de tus ingresos. Actualmente: ${savingsRate.toStringAsFixed(0)}%');
      }
    } else {
      consejos.add('Reduce gastos en categorías no esenciales.');
      consejos.add('Busca formas de aumentar tus ingresos.');
    }

    if (transactions.length < 5) {
      consejos.add('Agrega más transacciones para obtener mejores análisis.');
    }

    return {
      'resumen': resumen,
      'consejos': consejos,
      'alerta': alerta,
    };
  }

  Future<String> categorizeTransaction(String description) async {
    return _localCategorize(description);
  }

  String _localCategorize(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('starbucks') || desc.contains('cafe') || 
        desc.contains('mcdonald') || desc.contains('restaurant') ||
        desc.contains('comida') || desc.contains('almuerzo') || desc.contains('pizza')) {
      return 'Comida';
    } else if (desc.contains('uber') || desc.contains('taxi') || 
               desc.contains('gasolina') || desc.contains('combustible') ||
               desc.contains('bus') || desc.contains('metro')) {
      return 'Transporte';
    } else if (desc.contains('netflix') || desc.contains('spotify') || 
               desc.contains('amazon') || desc.contains('pelicula') ||
               desc.contains('cine') || desc.contains('juego')) {
      return 'Entretenimiento';
    } else if (desc.contains('supermercado') || desc.contains('walmart') ||
               desc.contains('tienda') || desc.contains('compra')) {
      return 'Compras';
    } else if (desc.contains('farmacia') || desc.contains('doctor') ||
               desc.contains('medico') || desc.contains('hospital')) {
      return 'Salud';
    }
    return 'Otros';
  }
}
