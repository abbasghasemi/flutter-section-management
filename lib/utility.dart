import 'package:flutter/cupertino.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

int dateTimestamp() {
  final datetime = Jalali.now();
  return Jalali(datetime.year, datetime.month, datetime.day)
      .millisecondsSinceEpoch ~/
      1000;
}

String timestampToShamsi(int ts) {
  return Jalali.fromMillisecondsSinceEpoch(ts * 1000).formatCompactDate();
}

int indexOfWeek(int ts) {
  return Jalali.fromMillisecondsSinceEpoch(ts * 1000).weekDay - 1;
}

String nameOfWeek(int ts) {
  if (ts > 6) {
    ts = indexOfWeek(ts);
  }
  return [
    "شنبه",
    "یک شنبه",
    "دو شنبه",
    "سه شنبه",
    "چهار شنبه",
    "پنج شنبه",
    "جمعه"
  ][ts];
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
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CupertinoDialogAction(
              child: Text(btnName),
              onPressed: () => Navigator.pop(context),
            )),
      ],
    ),
  );
}

class SwitchWidgetStateProperty implements WidgetStateProperty<MouseCursor> {
  const SwitchWidgetStateProperty();

  @override
  MouseCursor resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return SystemMouseCursors.forbidden;
    }
    return SystemMouseCursors.click;
  }
}

class CupertinoPageBack extends StatelessWidget {
  final String? previousPageTitle;
  const CupertinoPageBack({super.key, this.previousPageTitle});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        mouseCursor: SystemMouseCursors.click,
        onPressed: () {
          Navigator.of(context).pop();
        },
        padding: EdgeInsets.zero,
        child: previousPageTitle == null
            ? Icon(
                CupertinoIcons.back,
                color: CupertinoColors.activeBlue,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.back,
                    color: CupertinoColors.activeBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    previousPageTitle!,
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ));
  }
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

class DiagonalPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const DiagonalPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
