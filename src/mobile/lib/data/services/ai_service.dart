import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/budget.dart';

class AiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> getFinancialInsights(
    List<Transaction> transactions,
    List<Budget> budgets,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/insights'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'budgets': budgets.map((b) => b.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'resumen': 'No se pudieron obtener insights en este momento.',
          'consejos': [],
          'alerta': null,
        };
      }
    } catch (e) {
      return {
        'resumen': 'Error de conexión con el servidor.',
        'consejos': [],
        'alerta': null,
      };
    }
  }

  Future<String> categorizeTransaction(String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/categorize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['category'];
      }
    } catch (e) {
      // Fallback a categorización local
    }
    return _localCategorize(description);
  }

  String _localCategorize(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('starbucks') || desc.contains('cafe') || 
        desc.contains('mcdonald') || desc.contains('restaurant')) {
      return 'Comida';
    } else if (desc.contains('uber') || desc.contains('taxi') || 
               desc.contains('gasolina') || desc.contains('combustible')) {
      return 'Transporte';
    } else if (desc.contains('netflix') || desc.contains('spotify') || 
               desc.contains('amazon') || desc.contains('compra')) {
      return 'Entretenimiento';
    } else if (desc.contains('supermercado') || desc.contains('walmart') ||
               desc.contains('tienda')) {
      return 'Compras';
    }
    return 'Otros';
  }
}
