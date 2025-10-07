import 'package:flutter/cupertino.dart';
import 'package:section_management/providers/app_provider.dart';


class AppThemeProvider extends ChangeNotifier {

  void change(AppProvider appProvider) {
    AppThemeProvider.light = !appProvider.isLightTheme();
    appProvider.setThemeStatus(AppThemeProvider.light);
    notifyListeners();
  }

  static bool light = true;

  CupertinoThemeData get theme {
    _apply();
    return light
        ? CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1368F4),
      textTheme: CupertinoTextThemeData(),
      applyThemeToAll: true,
    )
        : CupertinoThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF16202a),
      barBackgroundColor: const Color(0xFF16202a),
      primaryColor: const Color(0xFF1368F4),
      primaryContrastingColor: const Color(0xfff8f8f8),
      textTheme: CupertinoTextThemeData(),
      applyThemeToAll: true,
    );
  }

  static late Color toolbarColor;
  static late Color backgroundColor;
  static late Color backgroundColorDeActivated;
  static late Color backgroundColorActivated;
  static late Color textColor;
  static late Color textTitleColor;

  static void _apply() {
    if (light) {
      toolbarColor = const Color(0xfff9faf9);
      backgroundColor = const Color(0xffffffff);
      backgroundColorDeActivated = const Color.fromARGB(20, 60, 60, 67);
      backgroundColorActivated = const Color(0xFFF0F7FF);
      textColor = const Color(0xff2e2e2e);
      textTitleColor = const Color(0xff000000);
    } else {
      toolbarColor = const Color(0xff1f2c3a);
      backgroundColor = const Color(0xFF16202a);
      backgroundColorDeActivated = const Color.fromARGB(45, 60, 60, 67);
      backgroundColorActivated = const Color(0xff10171e);
      textColor = const Color(0xffe4e4e4);
      textTitleColor = const Color(0xffffffff);
    }
  }

}