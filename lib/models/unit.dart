class Unit {
  final int? id;
  final String name;
  final int maxUsage;

  Unit({
    this.id,
    required this.name,
    required this.maxUsage,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      maxUsage: map['max_usage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'max_usage': maxUsage,
    };
  }
}
