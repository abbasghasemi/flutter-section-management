import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/utility.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import 'models/enums.dart';
import 'models/force.dart';
import 'models/leave.dart';
import 'models/post.dart';

class Report {
  static Future<void> presence(
      AppProvider appProvider, Jalali startDate, Jalali endDate) async {
    final Workbook workbook = Workbook();
    final globalStyle = workbook.styles.add("globalStyle");
    globalStyle.fontColor = '#000000';
    globalStyle.hAlign = HAlignType.center;
    globalStyle.vAlign = VAlignType.center;
    globalStyle.fontSize = 14;
    globalStyle.fontName = "B Nazanin";
    globalStyle.wrapText = true;
    for (int i = 0, j = endDate.distanceFrom(startDate) + 1; i < j; i++) {
      Jalali currentDate = startDate.addDays(i);
      int currentTs = currentDate.millisecondsSinceEpoch ~/ 1000;
      List<Force> forces = await appProvider.getForcesByUnitIds(
          appProvider.unitsPost(), true, currentTs);
      forces.sort((a, b) => a.lastName.compareTo(b.lastName));
      final Worksheet sheet =
          i == 0 ? workbook.worksheets[0] : workbook.worksheets.add();
      sheet.name = timestampToShamsi(currentTs).replaceAll("/", "-");
      sheet.pageSetup.orientation = ExcelPageOrientation.portrait;
      sheet.pageSetup.paperSize = ExcelPaperSize.paperA4;
      sheet.pageSetup.bottomMargin = 0.75;
      sheet.pageSetup.topMargin = 0.75;
      sheet.pageSetup.leftMargin = 0.25;
      sheet.pageSetup.rightMargin = 0.25;
      sheet.pageSetup.headerMargin = 0;
      sheet.pageSetup.footerMargin = 0;
      sheet.pageSetup.isFitToPage = false;
      sheet.showGridlines = false;
      sheet.isRightToLeft = true;
      sheet.getRangeByName('A1').setText('سطح (1 از 3)');
      sheet.getRangeByName('B1').setText('تاریخ');
      sheet.getRangeByName('C1').setText('وضعیت');
      sheet.getRangeByName('D1').setText('نوع عضویت');
      sheet.getRangeByName('E1').setText('کد ملی');
      sheet.getRangeByName('F1').setText('نام خانوادگی');
      sheet.getRangeByName('G1').setText('نام');
      sheet.setRowHeightInPixels(1, 50);
      sheet.setColumnWidthInPixels(1, 110);
      sheet.setColumnWidthInPixels(2, 110);
      sheet.setColumnWidthInPixels(3, 60);
      sheet.setColumnWidthInPixels(4, 90);
      sheet.setColumnWidthInPixels(5, 135);
      sheet.setColumnWidthInPixels(6, 190);
      sheet.setColumnWidthInPixels(7, 190);
      for (int row = 0; row < forces.length; row++) {
        Force force = forces[row];
        int status = _getStatusForDate(
            force, currentTs, await appProvider.getLeavesByForceId(force.id!));
        sheet.setRowHeightInPixels(row + 2, 30);
        sheet.getRangeByIndex(row + 2, 1).setText('3');
        sheet.getRangeByIndex(row + 2, 2).setText(sheet.name);
        sheet.getRangeByIndex(row + 2, 3).setNumber(status.toDouble());
        sheet.getRangeByIndex(row + 2, 4).setText('وظیفه');
        sheet.getRangeByIndex(row + 2, 5).setText(force.codeMeli);
        sheet.getRangeByIndex(row + 2, 6).setText(force.lastName);
        sheet.getRangeByIndex(row + 2, 7).setText(force.firstName);
      }
      final range = sheet.getRangeByIndex(1, 1, forces.length + 1, 7);
      range.cellStyle = globalStyle;
      range.cellStyle.borders.all.lineStyle = LineStyle.thin;
      range.cellStyle.borders.all.color = '#000000';
      final style = sheet.getRangeByName("A1:G1").cellStyle;
      style.bold = true;
      style.fontName = "B Titr";
      style.backColorRgb = Colors.green.shade100;
    }
    final sheet = workbook.worksheets.add();
    sheet.name = "راهنما";
    sheet.isRightToLeft = true;
    int i = 1;
    sheet.setColumnWidthInPixels(i, 100);
    for (var name in [
      "1- حاضر",
      "2- غایب",
      "3- مرخصی",
      "4- استعلاجی",
      "5- ماموریت"
    ]) {
      final range = sheet.getRangeByIndex(i, 1);
      range.cellStyle = globalStyle;
      sheet.setRowHeightInPixels(i, 50);
      range.text = name;
      i++;
    }
    await _export(workbook, startDate, endDate, 'presence_report');
  }

  static Future<void> postCount(
      AppProvider appProvider, Jalali startDate, Jalali endDate) async {
    int startTs = startDate.millisecondsSinceEpoch ~/ 1000;
    int endTs = endDate.millisecondsSinceEpoch ~/ 1000;
    final List<Post> posts =
        await appProvider.getRangePostsByTs(startTs, endTs);
    Map<int, int> postCounts = {};
    for (var post in posts) {
      postCounts[post.forceId] = (postCounts[post.forceId] ?? 0) + 1;
    }

    List<Force> forces = [];
    for (var forceId in postCounts.keys) {
      Force? force = await appProvider.getForceById(forceId);
      if (force != null) forces.add(force);
    }
    forces.sort((a, b) => a.lastName.compareTo(b.lastName));

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'تعداد پست‌ها';

    sheet.getRangeByName('A1').setText('نام و نام خانوادگی (نام پدر)');
    sheet.getRangeByName('B1').setText('کد ملی');
    sheet.getRangeByName('C1').setText('وضعیت تاهل');
    sheet.getRangeByName('D1').setText('واحد');
    sheet.getRangeByName('E1').setText('تعداد پست');
    sheet.pageSetup.orientation = ExcelPageOrientation.portrait;
    sheet.pageSetup.paperSize = ExcelPaperSize.paperA4;
    sheet.pageSetup.bottomMargin = 0.75;
    sheet.pageSetup.topMargin = 0.75;
    sheet.pageSetup.leftMargin = 0.25;
    sheet.pageSetup.rightMargin = 0.25;
    sheet.pageSetup.headerMargin = 0;
    sheet.pageSetup.footerMargin = 0;
    sheet.pageSetup.isFitToPage = false;
    sheet.showGridlines = false;
    sheet.isRightToLeft = true;
    sheet.setRowHeightInPixels(1, 40);
    sheet.setColumnWidthInPixels(1, 300);
    sheet.setColumnWidthInPixels(2, 135);
    sheet.setColumnWidthInPixels(3, 90);
    sheet.setColumnWidthInPixels(4, 200);
    sheet.setColumnWidthInPixels(5, 80);

    final globalStyle = workbook.styles.add("globalStyle");
    globalStyle.fontColor = '#000000';
    globalStyle.hAlign = HAlignType.center;
    globalStyle.vAlign = VAlignType.center;
    globalStyle.fontSize = 14;
    globalStyle.fontName = "B Nazanin";
    globalStyle.wrapText = true;
    final range = sheet.getRangeByIndex(1, 1, forces.length + 1, 5);
    range.cellStyle = globalStyle;
    range.cellStyle.borders.all.lineStyle = LineStyle.thin;
    range.cellStyle.borders.all.color = '#000000';
    final style = sheet.getRangeByName("A1:E1").cellStyle;
    style.bold = true;
    style.fontName = "B Titr";
    style.backColorRgb = Colors.blue.shade100;

    for (int i = 0; i < forces.length; i++) {
      Force force = forces[i];
      int count = postCounts[force.id!] ?? 0;
      sheet.setRowHeightInPixels(i + 2, 30);
      sheet.getRangeByIndex(i + 2, 1).setText(
          '${force.firstName} ${force.lastName} (${force.fatherName})');
      sheet.getRangeByIndex(i + 2, 2).setText(force.codeMeli);
      sheet.getRangeByIndex(i + 2, 3).setText(force.isMarried ? "✅" : "");
      sheet.getRangeByIndex(i + 2, 4).setText(force.unitName);
      sheet.getRangeByIndex(i + 2, 5).setNumber(count.toDouble());
      if (i % 2 == 1) {
        sheet.getRangeByName("A${i + 2}:E${i + 2}").cellStyle.backColorRgb =
            Colors.grey.shade200;
      }
    }

    _export(workbook, startDate, endDate, "post_count_report");
  }

  static Future<void> unitForceInfo(AppProvider appProvider) async {
    final Workbook workbook = Workbook();
    final globalStyle = workbook.styles.add("globalStyle");
    globalStyle.fontColor = '#000000';
    globalStyle.hAlign = HAlignType.center;
    globalStyle.vAlign = VAlignType.center;
    globalStyle.fontSize = 14;
    globalStyle.fontName = "B Nazanin";
    globalStyle.wrapText = true;
    for (var n = 0; n < 2; n++) {
      final List<Force> forces = await appProvider.getForcesByUnitIds(
          appProvider.unitsPost(), n == 0, null);
      forces.sort((a, b) => a.lastName.compareTo(b.lastName));
      final Worksheet sheet =
          n == 0 ? workbook.worksheets[0] : workbook.worksheets.add();
      sheet.name = n == 0 ? 'آمار کلی' : 'آمار کلی سایر واحدها';

      sheet.getRangeByName('A1').setText('نام و نام خانوادگی (نام پدر)');
      sheet.getRangeByName('B1').setText('کد ملی');
      sheet.getRangeByName('C1').setText('کد پرونده');
      sheet.getRangeByName('D1').setText('متاهل');
      sheet.getRangeByName('E1').setText('بومی');
      sheet.getRangeByName('F1').setText('مسلح');
      sheet.getRangeByName('G1').setText('تاریخ معرفی');
      sheet.getRangeByName('H1').setText('تاریخ تسویه');
      sheet.getRangeByName('I1').setText('تعداد روز');
      sheet.getRangeByName('J1').setText('تعداد پست');
      sheet.getRangeByName('K1').setText('استحقاق');
      sheet.pageSetup.orientation = ExcelPageOrientation.portrait;
      sheet.pageSetup.paperSize = ExcelPaperSize.paperA4;
      sheet.pageSetup.bottomMargin = 0.75;
      sheet.pageSetup.topMargin = 0.75;
      sheet.pageSetup.leftMargin = 0.25;
      sheet.pageSetup.rightMargin = 0.25;
      sheet.pageSetup.headerMargin = 0;
      sheet.pageSetup.footerMargin = 0;
      sheet.pageSetup.isFitToPage = false;
      sheet.showGridlines = false;
      sheet.isRightToLeft = true;
      sheet.setRowHeightInPixels(1, 40);
      sheet.setColumnWidthInPixels(1, 300);
      sheet.setColumnWidthInPixels(2, 135);
      sheet.setColumnWidthInPixels(3, 70);
      sheet.setColumnWidthInPixels(4, 50);
      sheet.setColumnWidthInPixels(5, 50);
      sheet.setColumnWidthInPixels(6, 50);
      sheet.setColumnWidthInPixels(7, 110);
      sheet.setColumnWidthInPixels(8, 110);
      sheet.setColumnWidthInPixels(9, 80);
      sheet.setColumnWidthInPixels(10, 80);
      sheet.setColumnWidthInPixels(11, 80);

      final range = sheet.getRangeByIndex(1, 1, forces.length + 1, 11);
      range.cellStyle = globalStyle;
      range.cellStyle.borders.all.lineStyle = LineStyle.thin;
      range.cellStyle.borders.all.color = '#000000';
      final style = sheet.getRangeByName("A1:K1").cellStyle;
      style.bold = true;
      style.fontName = "B Titr";
      style.backColorRgb = Colors.red.shade100;

      for (int i = 0; i < forces.length; i++) {
        Force force = forces[i];
        final info = await appProvider.getForceInfo(force.id!);
        final leave = info['lastDateLeave'] == 0
            ? force.createdDate
            : info['lastDateLeave']!;
        final days = Jalali.fromMillisecondsSinceEpoch(leave * 1000)
            .distanceTo(Jalali.now());
        final value = (days / 30) * appProvider.getMultiplierOfTheMonth();
        sheet.setRowHeightInPixels(i + 2, 30);
        sheet.getRangeByIndex(i + 2, 1).setText(
            '${force.firstName} ${force.lastName} (${force.fatherName})');
        sheet.getRangeByIndex(i + 2, 2).setText(force.codeMeli);
        sheet.getRangeByIndex(i + 2, 3).setText(force.codeId);
        sheet.getRangeByIndex(i + 2, 4).setText(force.isMarried ? "✅" : "");
        sheet.getRangeByIndex(i + 2, 5).setText(force.isNative ? '✅' : '');
        sheet.getRangeByIndex(i + 2, 6).setText(force.canArmed ? '✅' : '');
        sheet
            .getRangeByIndex(i + 2, 7)
            .setText(timestampToShamsi(force.createdDate));
        sheet
            .getRangeByIndex(i + 2, 8)
            .setText(timestampToShamsi(force.endDate));
        sheet.getRangeByIndex(i + 2, 9).setNumber(days.toDouble());
        sheet
            .getRangeByIndex(i + 2, 10)
            .setNumber((info['postsCount'] as int).toDouble());
        sheet.getRangeByIndex(i + 2, 11).setText(value.toStringAsFixed(2));
        if (i % 2 == 1) {
          sheet.getRangeByName("A${i + 2}:K${i + 2}").cellStyle.backColorRgb =
              Colors.grey.shade200;
        }
      }
    }

    _export(workbook, null, null, "force_info_report");
  }

  static Future<void> _export(Workbook workbook, Jalali? startDate,
      Jalali? endDate, String name) async {
    final Directory docs = await getTemporaryDirectory();
    String path =
        '${docs.path}\\${name}_${timestampToShamsi(startDate == null ? dateTimestamp() : startDate.millisecondsSinceEpoch ~/ 1000).replaceAll("/", "-")}';
    if (endDate != null) {
      path +=
          '_to_${timestampToShamsi(endDate.millisecondsSinceEpoch ~/ 1000).replaceAll("/", "-")}';
    }
    path += '.xlsx';
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    await File(path).writeAsBytes(bytes, flush: true);
    OpenFilex.open(path);
  }

  static int _getStatusForDate(Force force, int dateTs, List<Leave> leaves) {
    for (var leave in leaves) {
      if (leave.fromDate <= dateTs &&
          (leave.toDate == null || leave.toDate! >= dateTs)) {
        switch (leave.leaveType) {
          case LeaveType.presence:
            return 3;
          case LeaveType.sick:
            return 4;
          case LeaveType.mission:
            return 5;
          case LeaveType.absent:
          case LeaveType.detention:
            return 2;
          case LeaveType.hourly:
            continue;
        }
      }
    }
    return 1;
  }
}
