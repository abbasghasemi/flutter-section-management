import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:section_management/persian_localizations.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/providers/force_provider.dart';
import 'package:section_management/screens/login_screen.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  final appProvider = AppProvider();
  await appProvider.open();
  runApp(Application(appProvider: appProvider));
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1280, 720);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "مدیریت نیروها";
    win.show();
    FilePicker.platform = FilePickerWindows();
  });
}

class Application extends StatelessWidget {
  final AppProvider appProvider;

  const Application({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppThemeProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider(create: (_) => AppRestartProvider()),
        ChangeNotifierProvider(create: (_) => ForceProvider()),
        ChangeNotifierProvider<AppThemeProvider>.value(value: appTheme),
      ],
      child: ListenableBuilder(
          listenable: appTheme,
          builder: (context, child) {
            final theme = appTheme.theme;
            return WindowBorder(
              color: AppThemeProvider.backgroundColorActivated,
              width: 1,
              child: CupertinoApp(
                title: '',
                theme: theme,
                home: LoginScreen(),
                localizationsDelegates: [
                  PersianLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                ],
                supportedLocales: const [Locale('fa', 'IR')],
                locale: const Locale('fa', 'IR'),
              ),
            );
          }),
    );
  }
}
