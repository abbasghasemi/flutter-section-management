import 'package:flutter/cupertino.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

int dateTimestamp() {
  final datetime = DateTime.now();
  return DateTime(datetime.year, datetime.month, datetime.day)
          .millisecondsSinceEpoch ~/
      1000;
}

String timestampToShamsi(int ts) {
  return Jalali.fromMillisecondsSinceEpoch(ts * 1000).formatCompactDate();
}

Future<T?> showMessageDialog<T>(
  BuildContext context, {
  String title = 'خطا',
  required String message,
  String btnName = 'تایید',
}) {
  return showCupertinoDialog(
    barrierDismissible: true,
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: Text(btnName),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

extension opt on String {
  bool operator <=(String value) {
    return this.compareTo(value) <= 0;
  }

  bool operator <(String value) {
    return this.compareTo(value) < 0;
  }

  bool operator >=(String value) {
    return this.compareTo(value) >= 0;
  }

  bool operator >(String value) {
    return this.compareTo(value) > 0;
  }
}
