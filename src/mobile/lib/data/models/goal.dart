class Goal {
  final String id;
  final String name;
  final double target;
  final double current;
  final DateTime? deadline;
  final String color;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.current,
    this.deadline,
    required this.color,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  double get remaining => target - current;
  bool get completed => current >= target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'current': current,
        'deadline': deadline?.toIso8601String(),
        'color': color,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        name: json['name'],
        target: (json['target'] as num).toDouble(),
        current: (json['current'] as num).toDouble(),
        deadline:
            json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        color: json['color'],
      );

  Goal copyWith({
    String? id,
    String? name,
    double? target,
    double? current,
    DateTime? deadline,
    String? color,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      current: current ?? this.current,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
    );
  }
}
