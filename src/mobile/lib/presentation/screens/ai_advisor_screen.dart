import 'package:flutter/material.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/budget.dart';
import 'package:the_app/data/services/ai_service.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final AiService _aiService = AiService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_initialized) return;
    _initialized = true;
    
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': '¡Hola! Soy tu Asesor Financiero IA. Puedo analizar tus transacciones y darte recomendaciones personalizadas. ¿Qué te gustaría saber?',
      });
    });
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    final insights = await _aiService.getFinancialInsights(
      [], // transactions
      [], // budgets
    );

    String response = insights['resumen'] ?? 'Analizando tus finanzas...';
    
    if (insights['consejos'] != null && (insights['consejos'] as List).isNotEmpty) {
      response += '\n\n📋 Consejos:\n';
      for (var consejo in insights['consejos']) {
        response += '\n• $consejo';
      }
    }

    if (insights['alerta'] != null) {
      response += '\n\n⚠️ ${insights['alerta']}';
    }

    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor IA'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['content'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildQuickButton('📊 Analizar gastos', () => _sendMessage('Analiza mis gastos del mes')),
          _buildQuickButton('💰 Tips de ahorro', () => _sendMessage('Dame tips para ahorrar')),
          _buildQuickButton('⚠️ Alertas', () => _sendMessage('¿Tengo alguna alerta de presupuesto?')),
          _buildQuickButton('📈 Tendencias', () => _sendMessage('¿Cuáles son mis tendencias de gasto?')),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
