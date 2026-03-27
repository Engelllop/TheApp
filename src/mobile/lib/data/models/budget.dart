class Budget {
  final String id;
  final String category;
  final double limit;
  final String color;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.color,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? limit,
    String? color,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
        'color': color,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        category: json['category'],
        limit: (json['limit'] as num).toDouble(),
        color: json['color'] ?? '#457b9d',
      );

  static List<Budget> getDefaultBudgets() => [
        Budget(id: '1', category: 'Comida', limit: 500, color: '#e63946'),
        Budget(id: '2', category: 'Transporte', limit: 300, color: '#457b9d'),
        Budget(
            id: '3', category: 'Entretenimiento', limit: 200, color: '#2a9d8f'),
        Budget(id: '4', category: 'Compras', limit: 400, color: '#e9c46a'),
        Budget(id: '5', category: 'Salud', limit: 200, color: '#f4a261'),
      ];
}
