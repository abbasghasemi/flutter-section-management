import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/screens/forces_screen.dart';
import 'package:section_management/screens/posts_screen.dart';
import 'package:section_management/screens/report_screen.dart';
import 'package:section_management/screens/settings_screen.dart';
import 'package:section_management/screens/states_screen.dart';
import 'package:section_management/screens/units_screen.dart';
import 'package:section_management/theme.dart';
import 'package:section_management/utility.dart';

final List<OverlayEntry> _overlay_widgets = [];

void _overlay_clear() {
  while (_overlay_widgets.isNotEmpty) _overlay_widgets.removeLast().remove();
}

int _indexed_stack_selected = 0;

late void Function(VoidCallback) _update_view;

bool _sidebar_opened = false;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final mq = MediaQuery.of(context);
    bool allow = false;
    bool startDragging = false;
    return Column(
      children: [
        GestureDetector(
          onDoubleTap: () {
            if (allow) {
              _overlay_clear();
              appWindow.maximizeOrRestore();
            }
          },
          onPanDown: (e) {
            if (e.localPosition.dx >= 44 && e.localPosition.dx <= 44 * 4 ||
                e.localPosition.dx >= mq.size.width - 40 * 3) {
              allow = false;
              return;
            }
            startDragging = false;
            allow = true;
          },
          onPanUpdate: (e) {
            if (!startDragging && allow) {
              startDragging = true;
              appWindow.startDragging();
            }
          },
          child: Container(
            decoration:
                BoxDecoration(color: DarkTheme.toolbarColor, boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
            ]),
            child: Row(
              children: [
                WindowButtons(),
                Expanded(
                  child: Text("Section management",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.actionSmallTextStyle),
                ),
                WindowsMenuButton(
                  isMenu: true,
                  label: 'Help',
                  onPressed: (_) => _menu_help(context, _),
                ),
                WindowsMenuButton(
                  isMenu: true,
                  label: 'Tools',
                  onPressed: (_) => _menu_tools(context, _),
                ),
                WindowsMenuButton(
                  isMenu: true,
                  label: 'View',
                  onPressed: (_) => _menu_view(context, _),
                ),
                WindowsMenuButton(
                  isMenu: true,
                  label: 'File',
                  onPressed: (_) => _menu_file(context, _),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Image.asset(
                    "assets/img/app_icon.png",
                    width: 24,
                    height: 24,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BodyHomeScreen(),
        ),
        Container(
          height: 30,
          decoration: BoxDecoration(color: DarkTheme.toolbarColor, boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
          ]),
          child: Row(
            children: [
              SizedBox(
                width: 10,
              ),
              Tooltip(
                message: 'سایدبار',
                child: CupertinoButton(
                  padding: EdgeInsetsGeometry.zero,
                  child: Icon(
                    CupertinoIcons.sidebar_right,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: () => _update_view
                      .call(() => _sidebar_opened = !_sidebar_opened),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    Jalali.now().formatShortDate(),
                    style: theme.textTheme.actionSmallTextStyle
                        .apply(color: Colors.white),
                  ),
                ),
              ),
              Stack(
                children: [
                  Icon(CupertinoIcons.heart_solid),
                  Positioned(
                    top: 2,
                    bottom: 2,
                    left: 3,
                    child: Text('AG',
                        style: theme.textTheme.actionSmallTextStyle.apply(
                            color: DarkTheme.toolbarColor, fontSizeDelta: -1)),
                  ),
                ],
              ),
              SizedBox(
                width: 5,
              ),
            ],
          ),
        )
      ],
    );
  }

  void _menu_help(BuildContext context, Offset offset) {
    _overlay_clear();
    _overlay_widgets.add(OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                top: offset.dy,
                child: CupertinoButton(
                  child: Text(""),
                  onPressed: () => _overlay_clear(),
                ),
              ),
              Positioned(
                top: offset.dy,
                left: offset.dx,
                child: Container(
                  width: 250,
                  height: 90,
                  decoration: BoxDecoration(
                      color: DarkTheme.toolbarColor,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      WindowsMenuButton(
                        width: 230,
                        hover: Colors.blueAccent,
                        label: "Open source license",
                        onPressed: (_) {
                          showMessageDialog(context,
                              message:
                                  'https://github.com/abbasghasemi/flutter-section-management/blob/master/LICENSE',
                              title: 'Open source license');
                          _overlay_clear();
                        },
                      ),
                      WindowsMenuButton(
                        hover: Colors.blueAccent,
                        width: 230,
                        label: "Github",
                        onPressed: (_) {
                          showMessageDialog(context,
                              message:
                                  'https://github.com/abbasghasemi/flutter-section-management',
                              title: 'Github');
                          _overlay_clear();
                        },
                      ),
                      Text(
                        "Developed by Abbas Ghasemi - 1404",
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .actionSmallTextStyle,
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
        canSizeOverlay: true));
    Overlay.of(context).insert(_overlay_widgets.last);
  }

  void _menu_tools(BuildContext context, Offset offset) {
    _overlay_clear();
    _overlay_widgets.add(OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                top: offset.dy,
                child: CupertinoButton(
                  child: Text(""),
                  onPressed: () => _overlay_clear(),
                ),
              ),
              Positioned(
                top: offset.dy,
                left: offset.dx,
                child: Container(
                  width: 100,
                  height: 42,
                  decoration: BoxDecoration(
                      color: DarkTheme.toolbarColor,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "تقویم",
                        onPressed: (_) {
                          _overlay_clear();
                          return showPersianDatePicker(
                              context: context,
                              initialDate: Jalali.now(),
                              firstDate: Jalali.now().add(years: -2),
                              lastDate: Jalali.now().add(years: 2),
                              confirmText: 'بستن',
                              initialEntryMode:
                                  PersianDatePickerEntryMode.calendarOnly);
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        canSizeOverlay: true));
    Overlay.of(context).insert(_overlay_widgets.last);
  }

  void _menu_view(BuildContext context, Offset offset) {
    _overlay_clear();
    _overlay_widgets.add(OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                top: offset.dy,
                child: CupertinoButton(
                  child: Text(""),
                  onPressed: () => _overlay_clear(),
                ),
              ),
              Positioned(
                top: offset.dy,
                left: offset.dx,
                child: Container(
                  width: 100,
                  height: 177,
                  decoration: BoxDecoration(
                      color: DarkTheme.toolbarColor,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "نیروها",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 0)
                            _update_view.call(() {
                              _indexed_stack_selected = 0;
                              _overlay_clear();
                            });
                        },
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "واحدها",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 1)
                            _update_view.call(() {
                              _indexed_stack_selected = 1;
                              _overlay_clear();
                            });
                        },
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "مکان‌ها",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 2)
                            _update_view.call(() {
                              _indexed_stack_selected = 2;
                              _overlay_clear();
                            });
                        },
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "لوح پستی",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 3)
                            _update_view.call(() {
                              _indexed_stack_selected = 3;
                              _overlay_clear();
                            });
                        },
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "آمار",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 4)
                            _update_view.call(() {
                              _indexed_stack_selected = 4;
                              _overlay_clear();
                            });
                        },
                      ),
                      WindowsMenuButton(
                        width: 80,
                        hover: Colors.blueAccent,
                        label: "تنظیمات",
                        onPressed: (_) {
                          if (_indexed_stack_selected != 5)
                            _update_view.call(() {
                              _indexed_stack_selected = 5;
                              _overlay_clear();
                            });
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        canSizeOverlay: true));
    Overlay.of(context).insert(_overlay_widgets.last);
  }

  void _menu_file(BuildContext context, Offset offset) {
    _overlay_clear();
    _overlay_widgets.add(OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                top: offset.dy,
                child: CupertinoButton(
                  child: Text(""),
                  onPressed: () => _overlay_clear(),
                ),
              ),
              Positioned(
                top: offset.dy,
                left: offset.dx,
                child: Container(
                  width: 150,
                  height: 139,
                  decoration: BoxDecoration(
                      color: DarkTheme.toolbarColor,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      WindowsMenuButton(
                        width: 130,
                        hover: Colors.blueAccent,
                        label: "بارگیری دیتابیس",
                        onPressed: (_) async {
                          _overlay_clear();
                          final dbPath = await _databaseFilePath();
                          final name = Jalali.now()
                              .toJalaliDateTime()
                              .replaceRange(10, 11, "-")
                              .replaceRange(13, 14, '-')
                              .replaceRange(16, 17, '-');
                          final app = context.read<AppProvider>();
                          app.close();
                          FilePicker.platform.saveFile(
                            lockParentWindow: true,
                            bytes: File(dbPath).readAsBytesSync(),
                            type: FileType.custom,
                            allowedExtensions: ['db'],
                            fileName: 'sm-' + name + '.db',
                          );
                          await app.open();
                        },
                      ),
                      WindowsMenuButton(
                        width: 130,
                        hover: Colors.blueAccent,
                        label: "بارگزای دیتابیس",
                        onPressed: (_) async {
                          _overlay_clear();
                          showCupertinoDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text("اخطار"),
                              content: Text("این عمل قابل بازگشت نیست"),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  child: Text("بارگزاری دیتابیس"),
                                  onPressed: () async {
                                    final app = context.read<AppProvider>();
                                    final appRestart = context.read<AppRestartProvider>();
                                    Navigator.pop(context);
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      lockParentWindow: true,
                                      type: FileType.custom,
                                      allowedExtensions: ['db'],
                                    );
                                    if (result != null &&
                                        result.paths.first != null) {
                                      final read = File(result.paths.first!);
                                      app.close();
                                      final file =
                                          File(await _databaseFilePath());
                                      file.writeAsBytesSync(
                                          read.readAsBytesSync());
                                      await app.restart();
                                      appRestart.restart();
                                    }
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: Text("بستن"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      WindowsMenuButton(
                        width: 130,
                        hover: Colors.blueAccent,
                        label: "حذف کامل اطلاعات",
                        onPressed: (_) {
                          _overlay_clear();
                          showCupertinoDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text("اخطار"),
                              content: Text(
                                  "این عمل قابل بازگشت نیست\nبا حذف اطلاعات برنامه بسته می شود"),
                              actions: [
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: Text("حذف کامل اطلاعات"),
                                  onPressed: () async {
                                    final app = context.read<AppProvider>();
                                    final appRestart = context.read<AppRestartProvider>();
                                    app.close();
                                    Navigator.pop(context);
                                    final dbPath = await _databaseFilePath();
                                    File(dbPath).deleteSync();
                                    await app.restart();
                                    appRestart.restart();
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: Text("بستن"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Divider(),
                      WindowsMenuButton(
                        width: 130,
                        hover: Colors.blueAccent,
                        label: "بستن",
                        onPressed: (_) {
                          context.read<AppProvider>().close();
                          appWindow.close();
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        canSizeOverlay: true));
    Overlay.of(context).insert(_overlay_widgets.last);
  }

  Future<String> _databaseFilePath() async {
    return (await getApplicationSupportDirectory()).path + '\\sm.db';
  }
}

class BodyHomeScreen extends StatefulWidget {
  const BodyHomeScreen({
    super.key,
  });

  @override
  State<BodyHomeScreen> createState() => _BodyHomeScreenState();
}

class _BodyHomeScreenState extends State<BodyHomeScreen> {
  void _update(VoidCallback vc) {
    setState(vc);
  }

  @override
  void initState() {
    _update_view = _update;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(color: DarkTheme.toolbarColor, boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                spreadRadius: 1,
                offset: Offset(0, 4))
          ]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                margin: EdgeInsetsGeometry.only(
                    top: 52.0 * _indexed_stack_selected + 2),
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border(
                    left: BorderSide(
                      width: 3,
                      color: Colors.blue,
                    ),
                  ),
                ),
                duration: Duration(milliseconds: 110),
              ),
              AnimatedSize(
                curve: Curves.ease,
                alignment: Alignment.centerRight,
                duration: Duration(milliseconds: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rightNavigationBarItem(
                      id: 0,
                      icon: CupertinoIcons.person_3,
                      label: 'نیروها',
                    ),
                    rightNavigationBarItem(
                      id: 1,
                      icon: CupertinoIcons.house,
                      label: 'واحدها',
                    ),
                    rightNavigationBarItem(
                      id: 2,
                      icon: CupertinoIcons.location,
                      label: 'مکان‌ها',
                    ),
                    rightNavigationBarItem(
                      id: 3,
                      icon: CupertinoIcons.table,
                      label: 'لوح پستی',
                    ),
                    rightNavigationBarItem(
                      id: 4,
                      icon: CupertinoIcons.doc_chart,
                      label: 'آمار',
                    ),
                    rightNavigationBarItem(
                      id: 5,
                      icon: CupertinoIcons.gear_alt,
                      label: 'تنظیمات',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _indexed_stack_selected,
            children: [
              navigator(const ForcesScreen()),
              navigator(const UnitsScreen()),
              navigator(const StatesScreen()),
              navigator(const PostsScreen()),
              navigator(const ReportScreen()),
              navigator(const SettingsScreen()),
            ],
          ),
        )
      ],
    );
  }

  Widget navigator(Widget widget) {
    return Navigator(
        observers: [HeroController()],
        onGenerateRoute: (rs) {
          return CupertinoPageRoute(builder: (context) => widget);
        });
  }

  Widget rightNavigationBarItem(
      {required int id,
      required IconData icon,
      required String label,
      activeColor = Colors.blue}) {
    return CupertinoButton(
      onPressed: () {
        if (_indexed_stack_selected != id) {
          setState(() {
            _indexed_stack_selected = id;
          });
        }
      },
      child: _sidebar_opened
          ? Row(
              spacing: 10,
              children: [
                Icon(
                  icon,
                  color: id == _indexed_stack_selected
                      ? activeColor
                      : Colors.white,
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 14,
                      color: id == _indexed_stack_selected
                          ? activeColor
                          : Colors.white),
                )
              ],
            )
          : Tooltip(
              message: label,
              verticalOffset: -12,
              margin: EdgeInsetsGeometry.only(right: 40),
              child: Icon(
                icon,
                color:
                    id == _indexed_stack_selected ? activeColor : Colors.white,
              ),
            ),
    );
  }
}

final _buttonColors = WindowButtonColors(
  iconNormal: Colors.white54,
  mouseOver: DarkTheme.backgroundColorDeActivated,
  mouseDown: DarkTheme.backgroundColorDeActivated,
  iconMouseDown: Colors.white,
);

final _closeButtonColors = WindowButtonColors(
  mouseOver: Colors.red,
  mouseDown: Colors.redAccent,
  iconNormal: Colors.white54,
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 44,
          child: CloseWindowButton(
            colors: _closeButtonColors,
            onPressed: () {
              context.read<AppProvider>().close();
              appWindow.close();
            },
          ),
        ),
        SizedBox.square(
          dimension: 44,
          child: appWindow.isMaximized
              ? RestoreWindowButton(
                  colors: _buttonColors,
                  onPressed: maximizeOrRestore,
                )
              : MaximizeWindowButton(
                  colors: _buttonColors,
                  onPressed: maximizeOrRestore,
                ),
        ),
        SizedBox.square(
          dimension: 44,
          child: MinimizeWindowButton(colors: _buttonColors),
        ),
      ],
    );
  }
}

class WindowsMenuButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final Function(Offset offset) onPressed;
  final double width;
  final double height;
  final Color hover;
  final bool isMenu;

  @override
  _WindowsMenuButtonState createState() => _WindowsMenuButtonState();

  WindowsMenuButton({
    Key? key,
    this.label,
    this.child,
    required this.onPressed,
    this.width = 44,
    this.height = 24,
    this.hover = Colors.white24,
    this.isMenu = false,
  })  : assert(child != null || label != null),
        super(key: key);
}

class _WindowsMenuButtonState extends State<WindowsMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        if (widget.isMenu && _overlay_widgets.isNotEmpty) {
          final rb = context.findRenderObject() as RenderBox;
          final offset = rb.localToGlobal(Offset.zero);
          widget.onPressed.call(Offset(offset.dx, offset.dy + rb.size.height));
        }
      }),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final rb = context.findRenderObject() as RenderBox;
          final offset = rb.localToGlobal(Offset.zero);
          widget.onPressed.call(Offset(offset.dx, offset.dy + rb.size.height));
        },
        child: AnimatedContainer(
            width: widget.width,
            height: widget.height,
            margin: EdgeInsetsGeometry.only(top: 3),
            padding: EdgeInsetsGeometry.only(bottom: 3),
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _isHovered ? widget.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: widget.child == null
                ? Center(
                    child: Text(
                    widget.label!,
                    style: theme.textTheme.actionSmallTextStyle
                        .apply(color: Colors.white, fontSizeDelta: -2),
                  ))
                : widget.child),
      ),
    );
  }
}
