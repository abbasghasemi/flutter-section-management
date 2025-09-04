import 'package:section_management/models/enums.dart';

class State {
  int? id;
  final String name;
  final bool isActive;
  final bool isArmed;
  final StateType stateType;
  final int unitId;

  State({
    this.id,
    required this.name,
    required this.isActive,
    required this.isArmed,
    required this.stateType,
    required this.unitId,
  });

  factory State.fromMap(Map<String, dynamic> map) {
    return State(
      id: map['id'],
      name: map['name'],
      isActive: map['is_active'] == 1,
      isArmed: map['is_armed'] == 1,
      stateType:
          StateType.values.firstWhere((i) => i.name == map['state_type']),
      unitId: map['unit_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'is_armed': isArmed ? 1 : 0,
      'state_type': stateType.name,
      'unit_id': unitId,
    };
  }
}
