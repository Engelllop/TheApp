class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'isExpense': isExpense,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    description: json['description'],
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    category: json['category'],
    isExpense: json['isExpense'],
  );
}
