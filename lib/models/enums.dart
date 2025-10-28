abstract interface class FaName {
  String get fa;
}

enum StateType implements FaName {
  post,
  senior_post,
  driver,
  storekeeper,
  senior,
  secretary;

  String get fa => switch (this) {
        post => 'پستی',
        senior_post => 'پاسبخش',
        driver => 'راننده',
        storekeeper => 'انباردار',
        senior => 'ارشد',
        secretary => 'منشی',
      };
}

enum LeaveType implements FaName {
  presence,
  hourly,
  sick,
  absent,
  detention,
  mission;

  String get fa => switch (this) {
        presence => 'حضور',
        hourly => 'ساعتی',
        sick => 'استعلاجی',
        absent => 'غیبت',
        detention => 'بازداشت',
        mission => 'ماموریت',
      };
}

enum PresenceType implements FaName {
  merit,
  persuasion,
  way,
  days_off;

  String get fa => switch (this) {
        merit => 'استحقاقی',
        persuasion => 'تشویقی',
        way => 'توراهی',
        days_off => 'روزهای استراحت',
      };
}

enum MissionType implements FaName {
  mission,
  days_off;

  String get fa => switch (this) {
        mission => 'ماموریت',
        days_off => 'روزهای استراحت',
      };
}

enum SickType implements FaName {
  sick,
  days_off;

  String get fa => switch (this) {
        sick => 'استعلاجی',
        days_off => 'روزهای استراحت',
      };
}

enum DetentionType implements FaName {
  vacuum,
  surplus,
  days_off;

  String get fa => switch (this) {
        vacuum => 'خلاء',
        surplus => 'مازاد',
        days_off => 'روزهای استراحت',
      };
}

enum HourlyType implements FaName {
  hour;

  String get fa => switch (this) {
        hour => 'ساعت',
      };
}

enum PostStatus implements FaName {
  ok,
  abandoned,
  cancel;

  String get fa => switch (this) {
        ok => 'موفق',
        abandoned => 'ترک شده',
        cancel => 'لغو شده',
      };
}
