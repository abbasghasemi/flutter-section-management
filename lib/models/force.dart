import 'package:section_management/models/enums.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/utility.dart';

class Force {
  int? id;
  final String codeMeli;
  final String codeId;
  final String firstName;
  final String lastName;
  final String fatherName;
  final bool isNative;
  final bool isMarried;
  final int endDate;
  final int createdDate;
  final bool canArmed;
  final int unitId;
  final String unitName;
  final int daysOff;
  final int workdays;
  final int phoneNo;
  final StateType stateType;
  int lastPostNo = 0;

  Force({
    this.id,
    required this.codeMeli,
    required this.codeId,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.isNative,
    required this.isMarried,
    required this.endDate,
    required this.createdDate,
    required this.canArmed,
    required this.unitId,
    required this.unitName,
    required this.daysOff,
    required this.workdays,
    required this.phoneNo,
    required this.stateType,
  });

  factory Force.fromMap(Map<String, dynamic> map) {
    return Force(
      id: map['id'],
      codeId: map['code_id'],
      codeMeli: map['code_meli'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      fatherName: map['father_name'],
      isNative: map['is_native'] == 1,
      isMarried: map['is_married'] == 1,
      endDate: map['end_date'],
      createdDate: map['created_date'],
      canArmed: map['can_armed'] == 1,
      unitId: map['unit_id'],
      unitName: map['unit_name'],
      daysOff: map['days_off'],
      workdays: map['work_days'],
      phoneNo: map['phone_no'],
      stateType:
          StateType.values.firstWhere((i) => i.name == map['state_type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code_meli': codeMeli,
      'code_id': codeId,
      'first_name': firstName,
      'last_name': lastName,
      'father_name': fatherName,
      'is_native': isNative ? 1 : 0,
      'is_married': isMarried ? 1 : 0,
      'end_date': endDate,
      'created_date': createdDate,
      'can_armed': canArmed ? 1 : 0,
      'unit_id': unitId,
      'unit_name': unitName,
      'days_off': daysOff,
      'work_days': workdays,
      'phone_no': phoneNo,
      'state_type': stateType.name,
    };
  }

  static String? compareForces(List<Unit> units, Force oldData, Force newData) {
    final changes = <String>[];
    bool update = false;
    if (oldData.codeMeli != newData.codeMeli) {
      changes.add('تغییر کد ملی از ${oldData.codeMeli} به ${newData.codeMeli}');
    }
    if (oldData.codeId != newData.codeId) {
      if (oldData.codeId == '') {
        update = true;
      } else {
        changes
            .add('تغییر کد پرونده از ${oldData.codeId} به ${newData.codeId}');
      }
    }
    if (oldData.firstName != newData.firstName) {
      changes.add('تغییر نام از ${oldData.firstName} به ${newData.firstName}');
    }
    if (oldData.lastName != newData.lastName) {
      changes.add(
          'تغییر نام خانوادگی از ${oldData.lastName} به ${newData.lastName}');
    }
    if (oldData.fatherName != newData.fatherName) {
      changes.add(
          'تغییر نام پدر از ${oldData.fatherName} به ${newData.fatherName}');
    }
    if (oldData.isNative != newData.isNative) {
      changes.add(
          'تغییر بومی بودن از ${oldData.isNative ? 'بومی' : 'غیربومی'} به ${newData.isNative ? 'بومی' : 'غیربومی'}');
    }
    if (oldData.isMarried != newData.isMarried) {
      changes.add(
          'تغییر وضعیت تاهل از ${oldData.isMarried ? 'متاهل' : 'مجرد'} به ${newData.isMarried ? 'متاهل' : 'مجرد'}');
    }
    if (oldData.endDate != newData.endDate) {
      changes.add(
          'تغییر تاریخ پایان خدمت از ${timestampToShamsi(oldData.endDate)} به ${timestampToShamsi(newData.endDate)}');
    }
    if (oldData.canArmed != newData.canArmed) {
      changes.add(
          'تغییر وضعیت از ${oldData.canArmed ? 'مسلح' : 'غیرمسلح'} به ${newData.canArmed ? 'مسلح' : 'غیرمسلح'}');
    }
    if (oldData.unitId != newData.unitId) {
      final oldUnit = units.firstWhere((u) => u.id == oldData.unitId).name;
      final newUnit = units.firstWhere((u) => u.id == newData.unitId).name;
      changes.add('تغییر واحد از $oldUnit به $newUnit');
    }
    if (oldData.daysOff != newData.daysOff) {
      changes.add(
          'تغییر روزهای استراحت از ${oldData.daysOff} به ${newData.daysOff}');
    }
    if (oldData.workdays != newData.workdays) {
      String getWeekStr(int mask) {
        final days = List.generate(
                7, (i) => (mask & (1 << i)) != 0 ? nameOfWeek(i) : null)
            .whereType<String>()
            .toList();
        return days.length == 7 ? 'تمامی ایام هفته' : days.join(' ,');
      }

      final oldStr = getWeekStr(oldData.workdays);
      final newStr = getWeekStr(newData.workdays);

      final msg = oldStr.isEmpty
          ? 'تغییر روزهای کاری به $newStr'
          : newStr.isEmpty
              ? 'حذف روزهای کاری $oldStr'
              : 'تغییر روزهای کاری از $oldStr به $newStr';

      if (msg.isNotEmpty) changes.add(msg);
    }
    if (oldData.phoneNo != newData.phoneNo) {
      if (oldData.phoneNo == 0) {
        update = true;
      } else {
        changes.add(
            'تغییر شماره تلفن از ${oldData.phoneNo} به ${newData.phoneNo}');
      }
    }
    if (oldData.stateType != newData.stateType) {
      changes.add(
          'تغییر نوع از ${oldData.stateType.fa} به ${newData.stateType.fa}');
    }
    if (oldData.createdDate != newData.createdDate) {
      changes.add(
          'تغییر تاریخ اعزام از ${timestampToShamsi(oldData.createdDate)} به ${timestampToShamsi(newData.createdDate)}');
    }
    return changes.isEmpty ? (update ? '' : null) : changes.join(', ');
  }
}
