import 'dart:convert';
import 'dart:math';

import 'package:section_management/models/enums.dart';
import 'package:section_management/models/leave_detail.dart';

class Leave {
  final int? id;
  final int forceId;
  final int fromDate;
  final int? toDate;
  final LeaveType leaveType;
  final List<LeaveDetail> details;

  Leave({
    this.id,
    required this.forceId,
    required this.fromDate,
    this.toDate,
    required this.leaveType,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'force_id': forceId,
      'from_date': fromDate,
      'to_date': toDate,
      'leave_type': leaveType.name,
      'details': detailsStrJson,
    };
  }

  factory Leave.fromMap(Map<String, dynamic> map) {
    return Leave(
      id: map['id'],
      forceId: map['force_id'],
      fromDate: map['from_date'],
      toDate: map['to_date'],
      leaveType:
          LeaveType.values.firstWhere((e) => e.name == map['leave_type']),
      details: (jsonDecode(map['details']) as List)
          .map((d) => LeaveDetail.fromMap(Map<String, dynamic>.from(d),
              LeaveType.values.firstWhere((e) => e.name == map['leave_type'])))
          .toList(),
    );
  }

  String compareChanges(
      Leave newLeave, String Function(int) timestampToShamsi) {
    final changes = <String>[];
    if (leaveType != newLeave.leaveType) {
      changes.add(
          'تغییر نوع مرخصی از ${leaveType.fa} به ${newLeave.leaveType.fa}');
    }
    if (fromDate != newLeave.fromDate) {
      changes.add(
          'تغییر تاریخ شروع از ${timestampToShamsi(fromDate)} به ${timestampToShamsi(newLeave.fromDate)}');
    }
    if (toDate != newLeave.toDate) {
      changes.add(
          'تغییر تاریخ پایان از ${toDate != null ? timestampToShamsi(toDate!) : 'نامشخص'} به ${newLeave.toDate != null ? timestampToShamsi(newLeave.toDate!) : 'نامشخص'}');
    }
    for (int i = 0, j = min(newLeave.details.length, details.length);
        i < j;
        i++) {
      final oldDetail = details[i];
      final newDetail = newLeave.details[i];
      if (oldDetail.title != newDetail.title) {
        changes.add('تغییر عنوان از ${oldDetail.fa} به ${newDetail.fa}');
      }
      if (oldDetail.days != newDetail.days) {
        if (oldDetail.title is HourlyType) {
          changes.add(
              'تغییر تعداد ${oldDetail.fa} از ${oldDetail.days} به ${newDetail.days}');
        } else {
          changes.add(
              'تغییر تعداد روزهای ${oldDetail.fa} از ${oldDetail.days} به ${newDetail.days}');
        }
      }
    }
    if (details.length > newLeave.details.length) {
      for (int i = newLeave.details.length, j = details.length; i < j; i++) {
        final oldDetail = details[i];
        changes.add('حذف ${oldDetail.fa} به تعداد روز ${oldDetail.days}');
      }
    } else if (details.length < newLeave.details.length) {
      for (int i = details.length, j = newLeave.details.length; i < j; i++) {
        final newDetail = newLeave.details[i];
        if (newDetail.title is HourlyType) {
          changes.add('اضافه شدن ${newDetail.fa} به تعداد ${newDetail.days}');
        } else {
          changes
              .add('اضافه شدن ${newDetail.fa} به تعداد روز ${newDetail.days}');
        }
      }
    }
    return changes.join(', ');
  }

  String? get detailsStrJson =>
      jsonEncode(details.map((d) => d.toMap()).toList());
}
