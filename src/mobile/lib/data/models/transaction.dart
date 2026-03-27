class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;
  final String accountId;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
    required this.accountId,
  });

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    bool? isExpense,
    String? accountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      accountId: accountId ?? this.accountId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'isExpense': isExpense,
        'accountId': accountId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        category: json['category'] ?? 'Otros',
        isExpense: json['isExpense'],
        accountId: json['accountId'] ?? '1',
      );
}
