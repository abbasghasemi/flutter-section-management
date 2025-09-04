import 'package:flutter/cupertino.dart';

class DarkTheme {
  static CupertinoThemeData get theme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF16202a),
      barBackgroundColor: const Color(0xFF16202a),
      primaryColor: const Color(0xFF1368F4),
      primaryContrastingColor: const Color(0xfff8f8f8),
      textTheme: CupertinoTextThemeData(),
      applyThemeToAll: true,
    );
  }

  static Color toolbarColor = const Color(0xff1f2c3a);
  static Color backgroundColor = const Color(0xFF16202a);
  static Color backgroundColorDeActivated =
      const Color.fromARGB(45, 60, 60, 67);
  static Color backgroundColorActivated = const Color(0xff10171e);
}
