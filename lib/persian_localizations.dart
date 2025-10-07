import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

class PersianMaterialLocalizations extends DefaultMaterialLocalizations {
  PersianMaterialLocalizations(this.locale);

  final Locale locale;

  @override
  String aboutListTileTitle(String applicationName) {
    return 'درباره $applicationName';
  }

  @override
  List<String> get narrowWeekdays => ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  String get alertDialogLabel => 'هشدار';

  @override
  String get anteMeridiemAbbreviation => 'ق.ظ';

  @override
  String get backButtonTooltip => 'بازگشت';

  @override
  String get calendarModeButtonLabel => 'تقویم';

  @override
  String get cancelButtonLabel => 'لغو';

  @override
  String get closeButtonLabel => 'بستن';

  @override
  String get closeButtonTooltip => 'بستن';

  @override
  String get collapsedIconTapHint => 'باز کردن';

  @override
  String get continueButtonLabel => 'ادامه';

  @override
  String get copyButtonLabel => 'کپی';

  @override
  String get cutButtonLabel => 'برش';

  @override
  String get dateHelpText => 'مثال: ۱۴۰۲/۰۷/۱۵';

  @override
  String get dateInputLabel => 'تاریخ را وارد کنید';

  @override
  String get dateOutOfRangeLabel => 'تاریخ خارج از محدوده است';

  @override
  String get datePickerHelpText => 'انتخاب تاریخ';

  @override
  String get dateRangeEndLabel => 'تاریخ پایان';

  @override
  String get dateRangePickerHelpText => 'انتخاب محدوده تاریخ';

  @override
  String get dateRangeStartLabel => 'تاریخ شروع';

  @override
  String get dateSeparator => '/';

  @override
  String get deleteButtonTooltip => 'حذف';

  @override
  String get dialModeButtonLabel => 'شماره‌گیر';

  @override
  String get dialogLabel => 'گفت‌وگو';

  @override
  String get drawerLabel => 'منوی ناوبری';

  @override
  String get expandedIconTapHint => 'بستن';

  @override
  String get firstPageTooltip => 'صفحه اول';

  @override
  String formatCompactDate(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.year}/${jalali.month}/${jalali.day}';
  }

  @override
  String formatDecimal(int number) {
    return NumberFormat.decimalPattern('fa').format(number);
  }

  @override
  String formatFullDate(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.formatter.wN}، ${jalali.day} ${jalali.formatter.mN} ${jalali.year}';
  }

  @override
  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final format = alwaysUse24HourFormat ? 'HH' : 'h';
    final hour = NumberFormat(format, 'fa').format(timeOfDay.hour);
    return hour;
  }

  @override
  String formatMediumDate(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.day} ${jalali.formatter.mN} ${jalali.year}';
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    return NumberFormat('mm', 'fa').format(timeOfDay.minute);
  }

  @override
  String formatMonthYear(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.formatter.mN} ${jalali.year}';
  }

  @override
  String formatShortDate(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.year % 100}/${jalali.month}/${jalali.day}';
  }


  @override
  String formatTimeOfDay(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final hour = formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat);
    final minute = formatMinute(timeOfDay);
    final period = alwaysUse24HourFormat ? '' : ' ${timeOfDay.period == DayPeriod.am ? anteMeridiemAbbreviation : postMeridiemAbbreviation}';
    return '$hour:$minute$period';
  }

  @override
  String formatYear(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    return '${jalali.year}';
  }

  @override
  String get hideAccountsLabel => 'مخفی کردن حساب‌ها';

  @override
  String get inputDateModeButtonLabel => 'ورودی متنی';

  @override
  String get inputTimeModeButtonLabel => 'ورودی متنی';

  @override
  String get invalidDateFormatLabel => 'فرمت تاریخ نامعتبر است';

  @override
  String get invalidDateRangeLabel => 'محدوده تاریخ نامعتبر است';

  @override
  String get invalidTimeLabel => 'زمان نامعتبر است';

  @override
  String get lastPageTooltip => 'صفحه آخر';

  @override
  String get licensesPageTitle => 'مجوزها';

  @override
  String get modalBarrierDismissLabel => 'بستن';

  @override
  String get moreButtonTooltip => 'بیشتر';

  @override
  String get nextMonthTooltip => 'ماه بعد';

  @override
  String get nextPageTooltip => 'صفحه بعد';

  @override
  String get okButtonLabel => 'تأیید';

  @override
  String get openAppDrawerTooltip => 'باز کردن منوی ناوبری';

  @override
  String get pasteButtonLabel => 'جای‌گذاری';

  @override
  String get popupMenuLabel => 'منوی بازشو';

  @override
  String get postMeridiemAbbreviation => 'ب.ظ';

  @override
  String get previousMonthTooltip => 'ماه قبل';

  @override
  String get previousPageTooltip => 'صفحه قبل';

  @override
  String get refreshIndicatorSemanticLabel => 'تازه‌سازی';

  @override
  String remainingTextFieldCharacterCount(int remaining) {
    return 'تعداد کاراکترهای باقی‌مانده: $remaining';
  }

  @override
  String get saveButtonLabel => 'ذخیره';

  @override
  String get searchFieldLabel => 'جستجو';

  @override
  String get selectAllButtonLabel => 'انتخاب همه';

  @override
  String get selectYearSemanticsLabel => 'انتخاب سال';

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    return '$selectedRowCount مورد انتخاب شده';
  }

  @override
  String get showAccountsLabel => 'نمایش حساب‌ها';

  @override
  String get showMenuTooltip => 'نمایش منو';

  @override
  String get signedInLabel => 'وارد شده';

  @override
  String tabLabel({required int tabIndex, required int tabCount}) {
    return 'تب $tabIndex از $tabCount';
  }
  @override
  String get timePickerDialHelpText => 'انتخاب زمان';

  @override
  String get timePickerHourLabel => 'ساعت';

  @override
  String get timePickerInputHelpText => 'وارد کردن زمان';

  @override
  String get timePickerMinuteLabel => 'دقیقه';

  @override
  String get unspecifiedDate => 'تاریخ مشخص نشده';

  @override
  String get unspecifiedDateRange => 'محدوده تاریخ مشخص نشده';

  @override
  String get viewLicensesButtonLabel => 'مشاهده مجوزها';
}

class PersianLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const PersianLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fa';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return PersianMaterialLocalizations(locale);
  }

  @override
  bool shouldReload(PersianLocalizationsDelegate old) => false;
}