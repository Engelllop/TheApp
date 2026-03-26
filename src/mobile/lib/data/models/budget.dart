class Budget {
  final String id;
  final String category;
  final double limit;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;
  double get percentage => limit > 0 ? (spent / limit * 100) : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'limit': limit,
    'spent': spent,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    category: json['category'],
    limit: (json['limit'] as num).toDouble(),
    spent: (json['spent'] as num).toDouble(),
  );
}
