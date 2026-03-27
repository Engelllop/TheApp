class Account {
  final String id;
  final String name;
  final String type;
  final String color;
  final double initialBalance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.initialBalance,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    double? initialBalance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'initialBalance': initialBalance,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        color: json['color'],
        initialBalance: (json['initialBalance'] as num).toDouble(),
      );

  static List<Account> getDefaultAccounts() => [
        Account(
            id: '1',
            name: 'BAC',
            type: 'Banco',
            color: '#e63946',
            initialBalance: 0),
        Account(
            id: '2',
            name: 'BCR',
            type: 'Banco',
            color: '#457b9d',
            initialBalance: 0),
        Account(
            id: '3',
            name: 'Efectivo',
            type: 'Efectivo',
            color: '#8ecae6',
            initialBalance: 0),
      ];
}
