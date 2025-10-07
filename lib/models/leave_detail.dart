import 'package:section_management/models/enums.dart';

class LeaveDetail {
  final Enum title;
  final int days;

  LeaveDetail({required this.title, required this.days});

  Map<String, dynamic> toMap() {
    return {
      'title': title.name,
      'days': days,
    };
  }

  factory LeaveDetail.fromMap(Map<String, dynamic> map, LeaveType leaveType) {
    final titleStr = map['title'] as String;
    final Enum title;
    if (leaveType == LeaveType.presence) {
      title = PresenceType.values.firstWhere((e) => e.name == titleStr);
    } else if (leaveType == LeaveType.mission) {
      title = MissionType.values.firstWhere((e) => e.name == titleStr);
    } else if (leaveType == LeaveType.sick) {
      title = SickType.values.firstWhere((e) => e.name == titleStr);
    } else {
      title = DetentionType.values.firstWhere((e) => e.name == titleStr);
    }
    return LeaveDetail(
      title: title,
      days: map['days'] as int,
    );
  }

  String get fa => (title as FaName).fa;
}
