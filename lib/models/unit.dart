class Unit {
  int? id;
  String name;
  int unitType;
  int maxUsage;
  String description;

  Unit({
    this.id,
    required this.name,
    required this.unitType,
    required this.maxUsage,
    required this.description,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      unitType: map['unit_type'],
      maxUsage: map['max_usage'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit_type': unitType,
      'max_usage': maxUsage,
      'description': description,
    };
  }
}
