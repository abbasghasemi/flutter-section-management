abstract interface class FaName {
  String get fa;
}

enum StateType implements FaName {
  post,
  senior_post,
  driver,
  senior,
  secretary;

  String get fa => switch (this) {
        post => 'پستی',
        senior_post => 'پاسبخش',
        driver => 'راننده',
        senior => 'ارشد',
        secretary => 'منشی',
      };
}

enum LeaveType implements FaName {
  presence,
  sick,
  absent,
  detention;

  String get fa => switch (this) {
        presence => 'حضور',
        sick => 'استعلاجی',
        absent => 'غیبت',
        detention => 'بازداشت',
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
