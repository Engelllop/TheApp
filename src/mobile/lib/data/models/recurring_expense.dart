class RecurringExpense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String accountId;
  final int dayOfMonth;
  final bool isActive;

  RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.dayOfMonth,
    required this.isActive,
  });

  RecurringExpense copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    String? accountId,
    int? dayOfMonth,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'accountId': accountId,
        'dayOfMonth': dayOfMonth,
        'isActive': isActive,
      };

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        accountId: json['accountId'],
        dayOfMonth: json['dayOfMonth'],
        isActive: json['isActive'],
      );
}
