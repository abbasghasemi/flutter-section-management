import 'package:section_management/models/enums.dart';

class PostDoc {
  final int stateId;
  final StateType stateType;
  final String stateName;
  final bool isArmed;
  final List<int> forcesId;

  PostDoc(
      {required this.stateId,
      required this.stateName,
      required this.stateType,
      required this.isArmed,
      required this.forcesId});

  factory PostDoc.fromMap(Map<String, dynamic> map) {
    return PostDoc(
      stateId: map['state_id'],
      stateName: map['state_name'],
      stateType:
          StateType.values.firstWhere((s) => s.name == map['state_type']),
      isArmed: map['is_armed'] ?? false,
      forcesId: List.castFrom(map['forces_id']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state_id': stateId,
      'state_name': stateName,
      'state_type': stateType.name,
      'is_armed': isArmed,
      'forces_id': forcesId,
    };
  }
}
