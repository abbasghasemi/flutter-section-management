import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/screens/login_screen.dart';
import 'package:section_management/services/database_service.dart';
import 'package:section_management/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.open();
  final prefs = await SharedPreferences.getInstance();
  final password = prefs.getString('password') ?? '1234';
  runApp(Application(password: password));
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1280, 720);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Section management";
    win.show();
    FilePicker.platform = FilePickerWindows();
  });
}

class Application extends StatelessWidget {
  final String password;

  const Application({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AppRestartProvider()),
      ],
      child: WindowBorder(
        color: DarkTheme.backgroundColorActivated,
        width: 1,
        child: CupertinoApp(
          title: '',
          theme: DarkTheme.theme,
          home: LoginScreen(correctPassword: password),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fa', 'IR')],
          locale: const Locale('fa', 'IR'),
        ),
      ),
    );
  }
}
