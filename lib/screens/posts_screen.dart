import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/post.dart';
import 'package:section_management/models/post_doc.dart';
import 'package:section_management/models/state.dart' as model;
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/utility.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  int _selectedDateTs = dateTimestamp();
  List<model.State> _states = [];
  List<Post> _posts = [];
  List<PostDoc> _postsDoc = [];
  bool _isCreated = false;
  bool _isEdited = false;
  bool _loading = false;
  int _countOfWarning = 0;
  late AppRestartProvider _appRestart;
  final GlobalKey _tableKey = GlobalKey();
  late OverlayEntry _overlay;
  int _maxColumn = 0;
  double _fontSizeNameDelta = 0;
  double _fontSizeTitleDelta = 0;

  Future<Uint8List> _captureTable() async {
    RenderRepaintBoundary boundary =
        _tableKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _exportToPDF() async {
    final imageBytes = await _captureTable();
    final doc = pw.Document(pageMode: PdfPageMode.fullscreen);

    final image = pw.MemoryImage(imageBytes);
    final margin = pw.EdgeInsets.all(5);
    doc.addPage(
      pw.Page(
        orientation: pw.PageOrientation.landscape,
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginBottom: margin.bottom,
          marginLeft: margin.left,
          marginRight: margin.right,
          marginTop: margin.top,
        ),
        build: (pw.Context context) {
          return pw.Image(image);
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          '${timestampToShamsi(dateTimestamp()).replaceAll("/", "-")}.pdf',
    );
  }

  void _restart() {
    _loadPosts();
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
    });
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _postsDoc = appProvider.getPostsDocByDate(_selectedDateTs);
    if (_postsDoc.isEmpty) {
      _states = appProvider.states.where((state) => state.isActive).toList();
      _generateProposal(false);
    } else {
      _states.clear();
      _posts = appProvider.getPostsByDate(_selectedDateTs);
      _countOfWarning =
          appProvider.validateAssignments(_posts, _selectedDateTs);
      for (var postDoc in _postsDoc) {
        var ok = true;
        for (var state in _states) {
          if (state.id == postDoc.stateId) {
            ok = false;
            break;
          }
        }
        if (ok) {
          _states.add(appProvider.states
              .firstWhere((state) => state.id == postDoc.stateId));
        }
      }
      setState(() {
        _loading = false;
        _isCreated = true;
        _isEdited = false;
      });
    }
  }

  Future<void> _generateProposal([bool deletePrevious = true]) async {
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (deletePrevious) appProvider.deletePosts(_selectedDateTs);
    final proposals =
        await appProvider.generateProposal(_selectedDateTs, _states);
    _posts = proposals['posts'] as List<Post>;
    _postsDoc = proposals['postsDoc'] as List<PostDoc>;
    _countOfWarning = proposals['countOfWarning'];
    setState(() {
      _loading = false;
      _isCreated = false;
      _isEdited = false;
    });
  }

  void _rawPosts() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final proposals = appProvider.rawPosts(_selectedDateTs, _states);
    _posts = proposals['posts'] as List<Post>;
    _postsDoc = proposals['postsDoc'] as List<PostDoc>;
    _countOfWarning = proposals['countOfWarning'];
    setState(() {});
  }

  Future<void> _confirmProposal() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.savePosts(_postsDoc, _posts, _selectedDateTs);
    setState(() {
      _isCreated = true;
      _isEdited = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }
    final appProvider = Provider.of<AppProvider>(context);
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                child: Icon(CupertinoIcons.arrowtriangle_right),
                onPressed: () {
                  _selectedDateTs -= 60 * 60 * 24;
                  _loadPosts().ignore();
                }),
            Text(
                'لوح پستی ${nameOfWeek(_selectedDateTs)} ${timestampToShamsi(_selectedDateTs)}'),
            CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                child: Icon(CupertinoIcons.arrowtriangle_left),
                onPressed: () {
                  _selectedDateTs += 60 * 60 * 24;
                  _loadPosts().ignore();
                }),
          ],
        ),
        leading: !_isCreated || _isEdited
            ? Tooltip(
                message: 'تأیید لوح',
                child: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.checkmark_seal_fill),
                  onPressed: () async {
                    showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("هشدار"),
                        content: Text("ذخیره تغییرات قابل بازگشت نیست"),
                        actions: [
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                child: Text("تأیید لوح"),
                                onPressed: () {
                                  _confirmProposal();
                                  Navigator.pop(context);
                                },
                              )),
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                child: Text("بستن"),
                                onPressed: () => Navigator.pop(context),
                              )),
                        ],
                      ),
                    );
                  },
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'ایجاد لوح پیشنهادی',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.wand_stars),
                onPressed: () async {
                  if (_isCreated) {
                    showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("هشدار"),
                        content: Text('این عمل باعث حذف شدن لوح قبلی می گردد'),
                        actions: [
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: Text("ایجاد لوح پیشنهادی"),
                                onPressed: () async {
                                  await _generateProposal();
                                  Navigator.pop(context);
                                },
                              )),
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                child: Text("بستن"),
                                onPressed: () => Navigator.pop(context),
                              )),
                        ],
                      ),
                    );
                  } else {
                    await _generateProposal();
                  }
                },
              ),
            ),
            Tooltip(
              message: 'انتخاب تاریخ',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.calendar),
                onPressed: () async {
                  final date = await showPersianDatePicker(
                    context: context,
                    initialDate: Jalali.fromMillisecondsSinceEpoch(
                        _selectedDateTs * 1000),
                    firstDate: Jalali.now().add(years: -2),
                    lastDate: Jalali.now().add(years: 2),
                  );
                  if (date != null && date != _selectedDateTs) {
                    _selectedDateTs = dateTimestamp(date);
                    await _loadPosts();
                  }
                },
              ),
            ),
            Tooltip(
              message: 'پاک سازی لوح',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(Icons.cleaning_services_rounded),
                onPressed: () async {
                  if (_isCreated) {
                    showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("هشدار"),
                        content: Text('این عمل باعث حذف شدن لوح قبلی می گردد'),
                        actions: [
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: Text("پاک سازی لوح"),
                                onPressed: () async {
                                  _rawPosts();
                                  Navigator.pop(context);
                                },
                              )),
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoDialogAction(
                                child: Text("بستن"),
                                onPressed: () => Navigator.pop(context),
                              )),
                        ],
                      ),
                    );
                  } else {
                    _rawPosts();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
            top: AppThemeProvider.light ? 60 : 16,
            left: 16,
            right: 16,
            bottom: 16),
        child: Row(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _postsTable(
                      appProvider,
                      _tableRows(appProvider, theme, false),
                      false,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: Column(
                children: [
                  CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.location_circle_fill,
                          color: Colors.blueGrey,
                        ),
                        Text(
                          "مکان ها",
                          style: theme.textTheme.actionSmallTextStyle.apply(
                            color: AppThemeProvider.textTitleColor,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () async {
                      final states = appProvider.states.where((state) {
                        for (var value in _states) {
                          if (value.id == state.id) return false;
                        }
                        return true;
                      });
                      if (states.isEmpty) return;
                      final dataset = await showCupertinoModalPopup<
                          Map<model.State, ValueNotifier<bool>>>(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setModalState) {
                            final dataset =
                                <model.State, ValueNotifier<bool>>{};
                            return CupertinoActionSheet(
                              title: Text("انتخاب مکان جدید"),
                              actions: [
                                ...states.map(
                                  (state) {
                                    final unit = appProvider.units.firstWhere(
                                      (u) => u.id == state.unitId,
                                    );
                                    dataset[state] = ValueNotifier<bool>(false);
                                    return CupertinoActionSheetAction(
                                      mouseCursor: SystemMouseCursors.click,
                                      onPressed: () {
                                        dataset[state]!.value =
                                            !dataset[state]!.value;
                                      },
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: state.isActive
                                                    ? Colors.green
                                                    : Colors.orange),
                                            child: state.isArmed
                                                ? Icon(
                                                    CupertinoIcons
                                                        .arrow_2_circlepath,
                                                    color: Colors.white,
                                                    size: 17,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '${state.name} (${state.stateType.fa})'),
                                                Text(
                                                  '${unit.name}',
                                                  style: theme.textTheme
                                                      .actionSmallTextStyle,
                                                ),
                                              ],
                                            ),
                                          ),
                                          ValueListenableBuilder(
                                              valueListenable: dataset[state]!,
                                              builder: (context, value, child) {
                                                return CupertinoCheckbox(
                                                    value:
                                                        dataset[state]!.value,
                                                    onChanged: (_) {
                                                      dataset[state]!.value =
                                                          !dataset[state]!
                                                              .value;
                                                    });
                                              })
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  mouseCursor: SystemMouseCursors.click,
                                  child: const Text('افزودن'),
                                  onPressed: () =>
                                      Navigator.pop(context, dataset),
                                )
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                mouseCursor: SystemMouseCursors.click,
                                child: const Text('لغو'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            );
                          },
                        ),
                      );
                      if (dataset != null) {
                        setState(() {
                          dataset.forEach((state, status) {
                            if (status.value) {
                              _states.add(state);
                              _postsDoc.add(PostDoc(
                                stateId: state.id!,
                                stateName: state.name,
                                stateType: state.stateType,
                                isArmed: state.isArmed,
                                forcesId: List.filled(
                                    appProvider.getMaxPosts(state.stateType),
                                    0),
                              ));
                            }
                          });
                        });
                        if (!_isEdited && _isCreated) {
                          _confirmProposal();
                        }
                      }
                    },
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Icon(
                    Icons.error_rounded,
                    color: Colors.red,
                  ),
                  Text(
                    "${_countOfError()} عدد خطا",
                    style: theme.textTheme.actionSmallTextStyle.apply(
                      color: AppThemeProvider.textTitleColor,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.orange,
                  ),
                  Text(
                    "${_countOfWarning - _countOfError()} عدد هشدار",
                    style: theme.textTheme.actionSmallTextStyle.apply(
                      color: AppThemeProvider.textTitleColor,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Icon(
                    CupertinoIcons.app_badge_fill,
                    color: Colors.blue,
                  ),
                  Text(
                    "${_countOfEmpty()} نفر خالی",
                    style: theme.textTheme.actionSmallTextStyle.apply(
                      color: AppThemeProvider.textTitleColor,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.printer_fill,
                          color: Colors.deepPurple,
                        ),
                        Text(
                          "پرینت لوح",
                          style: theme.textTheme.actionSmallTextStyle.apply(
                            color: AppThemeProvider.textTitleColor,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      _fontSizeNameDelta = appProvider.fontSizeName() - 17;
                      _fontSizeTitleDelta = appProvider.fontSizeTitle() - 17;
                      _overlay = OverlayEntry(
                          builder: (context) {
                            return Container(
                              color: AppThemeProvider.backgroundColor,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: RepaintBoundary(
                                        key: _tableKey,
                                        child: Column(
                                          children: [
                                            CupertinoTextField(
                                              padding: EdgeInsetsGeometry.zero,
                                              placeholder: 'باسمه تعالی',
                                              controller: TextEditingController(
                                                  text: appProvider
                                                      .getPostContentText(1)),
                                              onChanged: (name) => appProvider
                                                  .setPostContentText(1, name),
                                              style: theme
                                                  .textTheme.navTitleTextStyle
                                                  .apply(
                                                fontSizeDelta:
                                                    _fontSizeTitleDelta + 4,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      width: 0,
                                                      color:
                                                          Colors.transparent)),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: CupertinoTextField(
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    2)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                2, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    maxLines: 1,
                                                    placeholder: 'عنوان ...',
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                ),
                                                Text(
                                                  'از مورخ ${timestampToShamsi(_selectedDateTs)} لغایت ${timestampToShamsi(_selectedDateTs + 24 * 60 * 60)}',
                                                  style: theme.textTheme
                                                      .navTitleTextStyle
                                                      .apply(
                                                    fontSizeDelta:
                                                        _fontSizeTitleDelta + 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            CupertinoTextField(
                                              padding: EdgeInsetsGeometry.zero,
                                              placeholder: 'زیر عنوان',
                                              controller: TextEditingController(
                                                  text: appProvider
                                                      .getPostContentText(3)),
                                              onChanged: (name) => appProvider
                                                  .setPostContentText(3, name),
                                              style: theme
                                                  .textTheme.navTitleTextStyle
                                                  .apply(
                                                fontSizeDelta:
                                                    _fontSizeTitleDelta + 2,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      width: 0,
                                                      color:
                                                          Colors.transparent)),
                                            ),
                                            SizedBox(
                                              height: 8,
                                            ),
                                            _postsTable(
                                              appProvider,
                                              _tableRows(
                                                  appProvider, theme, true),
                                              true,
                                            ),
                                            SizedBox(
                                              height: 8,
                                            ),
                                            Table(
                                              border: TableBorder.all(
                                                color: AppThemeProvider
                                                    .textTitleColor,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              defaultVerticalAlignment:
                                                  TableCellVerticalAlignment
                                                      .middle,
                                              columnWidths: {
                                                0: IntrinsicColumnWidth(),
                                                1: FlexColumnWidth(),
                                                2: IntrinsicColumnWidth(),
                                                3: FlexColumnWidth(),
                                                4: IntrinsicColumnWidth(),
                                                5: FlexColumnWidth(),
                                                6: IntrinsicColumnWidth(),
                                                7: FlexColumnWidth(),
                                              },
                                              children: [
                                                TableRow(children: [
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    placeholder: '......',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    4)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                4, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            1, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    placeholder: '......',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    5)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                5, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            2, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    placeholder: '......',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    6)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                6, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            3, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    placeholder: '......',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    7)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                7, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            4, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                ]),
                                                TableRow(children: [
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    placeholder: '......',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    8)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                8, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            5, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    9)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                9, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            6, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    10)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                10, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            7, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    11)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                11, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    controller:
                                                        _getCellController(
                                                            8, -1, ''),
                                                    padding: EdgeInsetsGeometry
                                                        .symmetric(
                                                            vertical: 12,
                                                            horizontal: 4),
                                                    style: theme
                                                        .textTheme.textStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta,
                                                    ),
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                ]),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 8,
                                            ),
                                            Table(
                                              defaultVerticalAlignment:
                                                  TableCellVerticalAlignment
                                                      .middle,
                                              border: TableBorder.all(
                                                color: AppThemeProvider
                                                    .textTitleColor,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              columnWidths: {
                                                0: FlexColumnWidth(),
                                                1: IntrinsicColumnWidth(),
                                                2: FlexColumnWidth(),
                                              },
                                              children: [
                                                TableRow(children: [
                                                  CupertinoTextField(
                                                    placeholder:
                                                        'محل امضای اول',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    12)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                12, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    placeholder:
                                                        'محل نوشتن توضیحات',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    13)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                13, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                  CupertinoTextField(
                                                    placeholder:
                                                        'محل امضای دوم',
                                                    controller:
                                                        TextEditingController(
                                                            text: appProvider
                                                                .getPostContentText(
                                                                    14)),
                                                    onChanged: (name) =>
                                                        appProvider
                                                            .setPostContentText(
                                                                14, name),
                                                    style: theme.textTheme
                                                        .navTitleTextStyle
                                                        .apply(
                                                      fontSizeDelta:
                                                          _fontSizeTitleDelta +
                                                              2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    expands: true,
                                                    maxLines: null,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent)),
                                                  ),
                                                ]),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: 64,
                                      children: [
                                        CupertinoButton(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            padding: EdgeInsets.zero,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.back,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  "بازگشت",
                                                ),
                                              ],
                                            ),
                                            onPressed: () {
                                              try {
                                                _overlay.remove();
                                              } catch (e, s) {}
                                            }),
                                        CupertinoButton(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            padding: EdgeInsets.zero,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "PDF",
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  "خروجی پی دی اف",
                                                ),
                                              ],
                                            ),
                                            onPressed: () => _exportToPDF()),
                                        CupertinoButton(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            padding: EdgeInsets.zero,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "EXCEL",
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  "خروجی اکسل",
                                                ),
                                              ],
                                            ),
                                            onPressed: () =>
                                                _exportToExcel(appProvider)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          canSizeOverlay: true);
                      Overlay.of(context).insert(_overlay);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Table _postsTable(
      AppProvider appProvider, List<TableRow> tableRows, bool print) {
    final column = tableRows.first.children.length - 1;
    final rows = List.generate(print ? 12 : column, (index) => index + 1);
    final columnWidth =
        Map.fromIterables(rows, rows.map((_) => FlexColumnWidth()));
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(
        color: print
            ? AppThemeProvider.textTitleColor
            : AppThemeProvider.backgroundColorDeActivated,
        borderRadius: BorderRadius.circular(3),
      ),
      columnWidths: {0: IntrinsicColumnWidth(), ...columnWidth},
      children: tableRows,
    );
  }

  final Map<String, TextEditingController> _cellController = {};
  TextEditingController _getCellController(int row, int col, String text) {
    String key = '$row-$col';
    if (!_cellController.containsKey(key)) {
      _cellController[key] = TextEditingController(text: text);
    } else {
      if (text.isNotEmpty && _cellController[key]!.text != text) {
        _cellController[key]!.text = text;
      }
    }
    return _cellController[key]!;
  }

  List<TableRow> _tableRows(
      AppProvider appProvider, CupertinoThemeData theme, bool print) {
    final showFatherName = appProvider.showFatherName();
    int rowIndex = -1;
    _maxColumn = 0;
    _postsDoc.forEach((state) {
      _maxColumn = max(_maxColumn, state.forcesId.length);
    });
    if (_maxColumn <= 2) {
      _maxColumn = appProvider.postCount();
    }
    final tableRows = <TableRow>[
      TableRow(children: [
        CustomPaint(
          painter: DiagonalPainter(
              color: print
                  ? AppThemeProvider.textTitleColor
                  : AppThemeProvider.backgroundColorDeActivated,
              strokeWidth: 1),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "                      ساعت\nموقعیت",
              style: theme.textTheme.navTitleTextStyle.apply(
                fontSizeDelta: print ? _fontSizeTitleDelta : -3,
              ),
            ),
          ),
        ),
        ...List.generate(print ? 12 : _maxColumn, (index) => index)
            .map((index) {
          return Center(
            child: Text(
              print
                  ? [
                      "10:00-08-00",
                      "12:00-10-00",
                      "14:00-12-00",
                      "16:00-14-00",
                      "18:00-16-00",
                      "20:00-18-00",
                      "22:00-20-00",
                      "00:00-22-00",
                      "02:00-00-00",
                      "04:00-02-00",
                      "06:00-04-00",
                      "08:00-06-00",
                    ][index]
                  : [
                      "پاس اول",
                      "پاس دوم",
                      "پاس سوم",
                      "پاس چهارم",
                      "پاس پنجم",
                      "پاس ششم",
                    ][index],
              style: theme.textTheme.navTitleTextStyle.apply(
                fontSizeDelta: print ? _fontSizeTitleDelta : -3,
              ),
            ),
          );
        })
      ])
    ];
    _postsDoc.forEach((state) {
      rowIndex++;
      final statePosts = _posts
          .where((post) => post.stateId == state.stateId)
          .toList()
        ..sort((a, b) => a.postNo.compareTo(b.postNo));
      final maxPosts = state.forcesId.length;
      final childState = Stack(
        children: [
          if (state.isArmed)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                CupertinoIcons.arrow_2_circlepath,
                color: AppThemeProvider.textTitleColor,
                size: 12,
              ),
            ),
          Positioned.fill(
            child: CupertinoButton(
              padding: EdgeInsetsGeometry.zero,
              mouseCursor:
                  print ? SystemMouseCursors.alias : SystemMouseCursors.click,
              onPressed: print
                  ? null
                  : () {
                      showCupertinoDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text("حذف ${state.stateName}"),
                          content: Text("ردیف حذف می گردد"),
                          actions: [
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: Text("حذف شود"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _postsDoc.removeWhere(
                                          (s) => s.stateId == state.stateId);
                                      _posts.removeWhere(
                                          (s) => s.stateId == state.stateId);
                                      _states.removeWhere(
                                          (s) => s.id == state.stateId);
                                    });
                                    if (!_isEdited && _isCreated) {
                                      _confirmProposal();
                                    }
                                  },
                                )),
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoDialogAction(
                                  child: Text("بستن"),
                                  onPressed: () => Navigator.pop(context),
                                )),
                          ],
                        ),
                      );
                    },
              child: Text(
                state.stateName,
                textAlign: TextAlign.center,
                style: theme.textTheme.navTitleTextStyle.apply(
                  fontSizeDelta: print ? _fontSizeTitleDelta : -3,
                ),
              ),
            ),
          ),
        ],
      );
      final rowCells = <Widget>[
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.fill,
          child: print
              ? childState
              : _buildDraggableState(child: childState, index: rowIndex),
        ),
      ];
      for (int i = 0, j = print ? 12 : _maxColumn; i < j; i++) {
        final int k;
        if (!print) {
          k = i;
        } else if (maxPosts >= 3) {
          k = i % 3;
        } else {
          k = [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1][i];
        }
        if (k >= maxPosts) {
          rowCells.add(Center(
            child: Text(
              '*******',
              style: theme.textTheme.textStyle.apply(
                fontSizeDelta: print ? _fontSizeNameDelta : 0,
              ),
            ),
          ));
        } else {
          final post = statePosts.firstWhere(
            (p) => p.postNo == k + 1,
            orElse: () => Post(
              id: null,
              forceId: 0,
              stateId: state.stateId,
              postNo: k + 1,
              postDate: _selectedDateTs,
              stateName: state.stateName,
              stateType: state.stateType,
              postStatus: PostStatus.ok,
              postDescription: '',
            ),
          );
          final force =
              post.forceId != 0 ? appProvider.getForceById(post.forceId) : null;
          final child = Container(
            color: _choiceColor(post, force, print),
            child: Row(
              children: [
                if (!print &&
                    post.warnings != null &&
                    post.warnings!.isNotEmpty &&
                    force != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Tooltip(
                      message: post.warnings!.join("\n"),
                      child: Icon(
                        post.hasError
                            ? Icons.error_rounded
                            : Icons.warning_rounded,
                        color: post.hasError ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                Expanded(
                  child: CupertinoListTile(
                    backgroundColorActivated:
                        _choiceColorActivated(post, force, print),
                    onTap: print
                        ? null
                        : () async {
                            final presentForces =
                                await appProvider.getPresentForces(
                                    date: _selectedDateTs,
                                    isMarried: appProvider.useMarried()
                                        ? null
                                        : false);
                            final assignedForceIds =
                                _posts.map((p) => p.forceId).toSet();
                            final availableForces = presentForces
                                .where((f) => !assignedForceIds.contains(f.id))
                                .toList();
                            availableForces
                                .sort((a, b) => a.unitId.compareTo(b.unitId));
                            String searchQuery = '';
                            final newForceId =
                                await showCupertinoModalPopup<int>(
                              context: context,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setModalState) =>
                                    CupertinoActionSheet(
                                  title: Column(
                                    children: [
                                      Text(
                                          'انتخاب نیرو برای پست ${i + 1} - ${state.stateName}'),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: CupertinoTextField(
                                          autofocus: true,
                                          placeholder: 'نام یا نام خانوادگی',
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: AppThemeProvider
                                                .backgroundColorDeActivated,
                                          ),
                                          onChanged: (value) {
                                            searchQuery = value;
                                            setModalState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    CupertinoActionSheetAction(
                                      mouseCursor: SystemMouseCursors.click,
                                      child: const Text('خالی'),
                                      onPressed: () =>
                                          Navigator.pop(context, 0),
                                    ),
                                    ...availableForces
                                        .where((force) =>
                                            searchQuery.isEmpty ||
                                            '${force.firstName} ${force.lastName}'
                                                .contains(searchQuery))
                                        .map((force) =>
                                            CupertinoActionSheetAction(
                                              mouseCursor:
                                                  SystemMouseCursors.click,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    force.canArmed
                                                        ? CupertinoIcons
                                                            .arrow_2_circlepath
                                                        : CupertinoIcons
                                                            .arrow_3_trianglepath,
                                                    color: force.canArmed
                                                        ? null
                                                        : Colors.orange,
                                                    size: 17,
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Expanded(
                                                      child: Text(
                                                    '${force.firstName} ${force.lastName} (${force.fatherName}) - ${force.unitName}',
                                                    textAlign: TextAlign.start,
                                                    style: force.canArmed
                                                        ? null
                                                        : theme
                                                            .textTheme.textStyle
                                                            .apply(
                                                                fontSizeFactor:
                                                                    1.2,
                                                                color: Colors
                                                                    .orange),
                                                  )),
                                                  FutureBuilder(
                                                      future: appProvider
                                                          .getLastPost(
                                                              force.id!),
                                                      builder: (context, snap) {
                                                        if (!snap.hasData ||
                                                            snap.data == null)
                                                          return Container();
                                                        final post = snap.data!;
                                                        return Text(
                                                          timestampToShamsi(post
                                                                  .postDate) +
                                                              " " +
                                                              post.stateName +
                                                              " (" +
                                                              post.postNo
                                                                  .toString() +
                                                              ") ",
                                                        );
                                                      }),
                                                ],
                                              ),
                                              onPressed: () => Navigator.pop(
                                                  context, force.id),
                                            )),
                                  ],
                                  cancelButton: CupertinoActionSheetAction(
                                    mouseCursor: SystemMouseCursors.click,
                                    child: const Text('لغو'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                            );
                            if (newForceId != null &&
                                newForceId != post.forceId) {
                              _posts.firstWhere(
                                (p) =>
                                    p.stateId == state.stateId &&
                                    p.postNo == i + 1,
                                orElse: () {
                                  _posts.add(Post(
                                    id: null,
                                    stateId: state.stateId,
                                    postNo: i + 1,
                                    postDate: _selectedDateTs,
                                    stateName: state.stateName,
                                    forceId: 0,
                                    stateType: state.stateType,
                                    postStatus: PostStatus.ok,
                                    postDescription: '',
                                  ));
                                  return _posts.last;
                                },
                              )
                                ..forceId = newForceId
                                ..hasError = false
                                ..warnings?.clear();
                              _postsDoc
                                  .firstWhere((p) => p.stateId == state.stateId)
                                  .forcesId[post.postNo - 1] = newForceId;
                              _countOfWarning = appProvider.validateAssignments(
                                  _posts, _selectedDateTs);
                              if (!_isEdited && _isCreated) {
                                _confirmProposal();
                              } else {
                                setState(() {
                                  _isEdited = true;
                                });
                              }
                            }
                          },
                    padding: EdgeInsets.all(print ? 4 : 8),
                    subtitle: print
                        ? null
                        : Text(
                            force == null ? '' : force.unitName,
                            style: theme.textTheme.actionSmallTextStyle,
                          ),
                    title: print
                        ? CupertinoTextField(
                            prefix: state.isArmed &&
                                    force != null &&
                                    !force.canArmed
                                ? Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: AppThemeProvider.textTitleColor,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  )
                                : null,
                            controller: _getCellController(
                                rowIndex,
                                k,
                                force != null
                                    ? '${force.firstName} ${force.lastName}${showFatherName ? ' (${force.fatherName})' : ''}'
                                    : ''),
                            padding: EdgeInsetsGeometry.zero,
                            style: theme.textTheme.textStyle.apply(
                              color: AppThemeProvider.textTitleColor,
                              fontSizeDelta: _fontSizeNameDelta,
                            ),
                            expands: true,
                            maxLines: null,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 0, color: Colors.transparent)),
                          )
                        : Text(
                            force != null
                                ? '${force.firstName} ${force.lastName}${showFatherName ? ' (${force.fatherName})' : ''}'
                                : '',
                            softWrap: true,
                            maxLines: 3,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.textStyle.apply(
                              color: AppThemeProvider.textTitleColor,
                              fontSizeDelta: print ? _fontSizeNameDelta : 0,
                            ),
                          ),
                  ),
                ),
                if (!print && force != null)
                  CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    padding: EdgeInsetsGeometry.zero,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: force.firstName +
                              ' ' +
                              force.lastName +
                              (showFatherName
                                  ? ' (${force.fatherName})'
                                  : '')));
                    },
                  )
              ],
            ),
          );
          rowCells.add(print
              ? child
              : _buildDraggableForce(
                  row: rowIndex,
                  col: i,
                  child: child,
                ));
        }
      }
      tableRows.add(TableRow(children: rowCells));
    });
    return tableRows;
  }

  void _swapForceCell(int fromRow, int fromCol, int toRow, int toCol) {
    final fromId = _postsDoc[fromRow].forcesId[fromCol];
    final toId = _postsDoc[toRow].forcesId[toCol];
    if (fromId == toId) return;
    _postsDoc[fromRow].forcesId[fromCol] = toId;
    _postsDoc[toRow].forcesId[toCol] = fromId;
    bool okFromPosts = false;
    bool okToPosts = false;
    _posts.forEach((post) {
      if (post.stateId == _postsDoc[fromRow].stateId &&
          post.postNo == fromCol + 1) {
        okFromPosts = true;
        post
          ..forceId = toId
          ..hasError = false
          ..warnings?.clear();
      } else if (post.stateId == _postsDoc[toRow].stateId &&
          post.postNo == toCol + 1) {
        okToPosts = true;
        post
          ..forceId = fromId
          ..hasError = false
          ..warnings?.clear();
      }
    });
    if (okFromPosts != okToPosts) {
      _posts.add(Post(
        id: null,
        stateId: _postsDoc[okFromPosts ? toRow : fromRow].stateId,
        postNo: (okFromPosts ? toCol : fromCol) + 1,
        postDate: _selectedDateTs,
        stateName: _postsDoc[okFromPosts ? toRow : fromRow].stateName,
        forceId: okFromPosts ? fromId : toId,
        stateType: _postsDoc[okFromPosts ? toRow : fromRow].stateType,
        postStatus: PostStatus.ok,
        postDescription: '',
      ));
    }
    _countOfWarning = context
        .read<AppProvider>()
        .validateAssignments(_posts, _selectedDateTs);
    if (!_isEdited && _isCreated) {
      _confirmProposal();
    } else {
      setState(() {
        _isEdited = true;
      });
    }
  }

  final Map<String, GlobalKey> _cellKeys = {};

  GlobalKey _getCellKey(int row, int col) {
    String key = '$row-$col';
    if (!_cellKeys.containsKey(key)) {
      _cellKeys[key] = GlobalKey();
    }
    return _cellKeys[key]!;
  }

  Widget _buildDraggableState({
    required Widget child,
    required int index,
  }) {
    return DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        bool isHighlighted = candidateData.isNotEmpty;
        return Draggable<int>(
          axis: Axis.vertical,
          data: index,
          feedback: Builder(builder: (context) {
            final RenderBox renderBox = _getCellKey(index, -1)
                .currentContext
                ?.findRenderObject() as RenderBox;
            final size = renderBox.size;
            return Container(
              decoration: BoxDecoration(
                  color: AppThemeProvider.backgroundColor,
                  borderRadius: BorderRadius.circular(5)),
              width: size.width,
              height: size.height,
              child: child,
            );
          }),
          childWhenDragging: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Opacity(
              opacity: 0,
              child: child,
            ),
          ),
          child: MouseRegion(
            key: _getCellKey(index, -1),
            cursor: isHighlighted
                ? SystemMouseCursors.move
                : SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isHighlighted ? Colors.blue.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isHighlighted
                    ? Border.all(color: Colors.blue, width: 1.5)
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
      onAcceptWithDetails: (details) {
        if (details.data != index) {
          setState(() {
            final a = min(details.data, index);
            final b = max(details.data, index);
            final c = _postsDoc.removeAt(a);
            _postsDoc.insert(a, _postsDoc.removeAt(b - 1));
            _postsDoc.insert(b, c);
            final d = _states.removeAt(a);
            _states.insert(a, _states.removeAt(b - 1));
            _states.insert(b, d);
          });
        }
      },
    );
  }

  Widget _buildDraggableForce({
    required Widget child,
    required int row,
    required int col,
  }) {
    return DragTarget<List<int>>(
      builder: (context, candidateData, rejectedData) {
        bool isHighlighted = candidateData.isNotEmpty;
        return Draggable<List<int>>(
          data: [row, col],
          feedback: Builder(builder: (context) {
            final RenderBox renderBox = _getCellKey(row, col)
                .currentContext
                ?.findRenderObject() as RenderBox;
            final size = renderBox.size;
            return Container(
              decoration: BoxDecoration(
                  color: AppThemeProvider.backgroundColor,
                  borderRadius: BorderRadius.circular(5)),
              width: size.width,
              height: size.height,
              child: child,
            );
          }),
          childWhenDragging: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Opacity(
              opacity: 0,
              child: child,
            ),
          ),
          child: MouseRegion(
            key: _getCellKey(row, col),
            cursor: isHighlighted
                ? SystemMouseCursors.move
                : SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isHighlighted ? Colors.blue.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isHighlighted
                    ? Border.all(color: Colors.blue, width: 1.5)
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
      onAcceptWithDetails: (details) {
        List<int> sourceData = details.data;
        if (sourceData.first != row || sourceData.last != col) {
          _swapForceCell(sourceData.first, sourceData.last, row, col);
        }
      },
    );
  }

  @override
  void dispose() {
    _appRestart.removeListener(_restart);
    super.dispose();
  }

  Color? _choiceColor(Post post, Force? force, bool print) {
    if (print) return null;
    if (post.forceId == 0 || force == null)
      return AppThemeProvider.textTitleColor.withAlpha(10);
    if (post.hasError) return Colors.redAccent.withAlpha(30);
    if (post.warnings != null && post.warnings!.isNotEmpty) {
      return Colors.orangeAccent.withAlpha(30);
    }
    return null;
  }

  Color? _choiceColorActivated(Post post, Force? force, bool print) {
    if (force == null || print)
      return AppThemeProvider.backgroundColorActivated;
    if (post.hasError) return Colors.redAccent.withAlpha(200);
    return post.warnings != null && post.warnings!.isNotEmpty
        ? Colors.orangeAccent.withAlpha(200)
        : AppThemeProvider.backgroundColorActivated;
  }

  int _countOfEmpty() {
    int count = 0;
    _postsDoc.forEach((i) =>
        count += i.forcesId.length - i.forcesId.where((i) => i != 0).length);
    return count;
  }

  int _countOfError() {
    int count = 0;
    _posts.forEach((i) => count += i.hasError ? 1 : 0);
    return count;
  }

  Future<void> _exportToExcel(AppProvider appProvider) async {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Posts';
    sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
    sheet.pageSetup.paperSize = xlsio.ExcelPaperSize.paperA4;
    sheet.pageSetup.bottomMargin = 0.75;
    sheet.pageSetup.topMargin = 0.75;
    sheet.pageSetup.leftMargin = 0.25;
    sheet.pageSetup.rightMargin = 0.25;
    sheet.pageSetup.headerMargin = 0;
    sheet.pageSetup.footerMargin = 0;
    sheet.pageSetup.isFitToPage = true;
    sheet.showGridlines = false;
    sheet.isRightToLeft = true;

    final globalStyle = workbook.styles.add("globalStyle");
    globalStyle.fontColor = '#000000';
    globalStyle.hAlign = xlsio.HAlignType.center;
    globalStyle.vAlign = xlsio.VAlignType.center;
    globalStyle.fontSize = 12;
    globalStyle.fontName = "B Nazanin";
    globalStyle.wrapText = true;
    sheet.getRangeByIndex(1, 1, 100, 13).cellStyle = globalStyle;

    int row = 1;
    xlsio.Range range = sheet.getRangeByName('A$row:M$row');
    range.merge();
    range.setText(appProvider.getPostContentText(1));
    range.cellStyle.fontName = "B Titr";
    range.cellStyle.bold = true;
    sheet.setRowHeightInPixels(row, 30);

    row++;
    range = sheet.getRangeByName('A$row:G$row');
    range.merge();
    range.setText(appProvider.getPostContentText(2));
    range.cellStyle.bold = true;
    range.cellStyle.hAlign = xlsio.HAlignType.right;
    range.cellStyle.fontName = "B Titr";
    range = sheet.getRangeByName('H$row:M$row');
    range.merge();
    range.setText(
        'از مورخ ${timestampToShamsi(_selectedDateTs)} لغایت ${timestampToShamsi(_selectedDateTs + 24 * 60 * 60)}');
    range.cellStyle.fontName = "B Titr";
    range.cellStyle.bold = true;
    range.cellStyle.hAlign = xlsio.HAlignType.left;
    sheet.setRowHeightInPixels(row, 30);

    row++;
    range = sheet.getRangeByName('A$row:M$row');
    range.merge();
    range.setText(appProvider.getPostContentText(3));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    sheet.setRowHeightInPixels(row, 30);

    row += 1;

    int start = row;
    sheet.getRangeByName('A$row').setText('موقعیت / ساعت');
    for (int col = 1; col <= 12; col++) {
      final times = [
        '08-00-10:00',
        '10-00-12:00',
        '12-00-14:00',
        '14-00-16:00',
        '16-00-18:00',
        '18-00-20:00',
        '20-00-22:00',
        '22-00-00:00',
        '00-00-02:00',
        '02-00-04:00',
        '04-00-06:00',
        '06-00-08:00'
      ];
      sheet.getRangeByIndex(row, col + 1).setText(times[col - 1]);
    }
    range = sheet.getRangeByName('A$row:M$row');
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    sheet.setRowHeightInPixels(row, 30);

    row++;
    final showFatherName = appProvider.showFatherName();
    _postsDoc.forEach((state) {
      final statePosts = _posts
          .where((post) => post.stateId == state.stateId)
          .toList()
        ..sort((a, b) => a.postNo.compareTo(b.postNo));
      final maxPosts = state.forcesId.length;
      sheet.getRangeByName('A$row').setText(state.stateName);
      for (int col = 1; col <= 12; col++) {
        final int k = (maxPosts >= 3)
            ? (col - 1) % 3
            : [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1][col - 1];
        if (k >= maxPosts) {
          sheet.getRangeByIndex(row, col + 1).setText('*******');
        } else {
          final post = statePosts.firstWhere((p) => p.postNo == k + 1,
              orElse: () => Post(
                  id: null,
                  forceId: 0,
                  stateId: state.stateId,
                  postNo: k + 1,
                  postDate: _selectedDateTs,
                  stateName: state.stateName,
                  stateType: state.stateType,
                  postStatus: PostStatus.ok,
                  postDescription: ''));
          final force =
              post.forceId != 0 ? appProvider.getForceById(post.forceId) : null;
          final text = force != null
              ? '${force.firstName} ${force.lastName}${showFatherName ? ' (${force.fatherName})' : ''}'
              : '';
          sheet.getRangeByIndex(row, col + 1).setText(text);
        }
      }
      sheet.setRowHeightInPixels(row, 50);
      row++;
    });

    range = sheet.getRangeByName("A${start}:M${row - 1}");
    range.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    range.cellStyle.borders.all.color = '#000000';
    range = sheet.getRangeByName("B${start + 1}:M${row - 1}");
    range.cellStyle.fontSize = 9;

    range = sheet.getRangeByName("A${start}:A${row - 1}");
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";

    row++;

    start = row;
    range = sheet.getRangeByName('A$row:B$row');
    range.setText(appProvider.getPostContentText(4));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('C$row:E$row').merge();
    range = sheet.getRangeByName('F$row:G$row');
    range.setText(appProvider.getPostContentText(5));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('H$row:I$row').merge();
    range = sheet.getRangeByName('J$row:K$row');
    range.setText(appProvider.getPostContentText(6));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('L$row:M$row').merge();
    row++;
    range = sheet.getRangeByName('A$row:B$row');
    range.setText(appProvider.getPostContentText(7));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('C$row:E$row').merge();
    range = sheet.getRangeByName('F$row:G$row');
    range.setText(appProvider.getPostContentText(8));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('H$row:I$row').merge();
    range = sheet.getRangeByName('J$row:K$row');
    range.setText(appProvider.getPostContentText(9));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    sheet.getRangeByName('L$row:M$row').merge();
    row++;
    range = sheet.getRangeByName('A$row:B$row');
    range.setText(appProvider.getPostContentText(10));
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.merge();
    if (appProvider.getPostContentText(11).isEmpty) {
      sheet.getRangeByName('C$row:M$row').merge();
    } else {
      sheet.getRangeByName('C$row:E$row').merge();
      range = sheet.getRangeByName('F$row:G$row');
      range.setText(appProvider.getPostContentText(11));
      range.cellStyle.bold = true;
      range.cellStyle.fontName = "B Titr";
      range.merge();
      sheet.getRangeByName('H$row:M$row').merge();
    }

    range = sheet.getRangeByName("A${start}:M${row}");
    range.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    range.cellStyle.borders.all.color = '#000000';
    sheet.setRowHeightInPixels(row - 2, 50);
    sheet.setRowHeightInPixels(row - 1, 50);
    sheet.setRowHeightInPixels(row, 50);

    row += 2;

    range = sheet.getRangeByName('A${row}:B$row');
    range.merge();
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.setText(appProvider.getPostContentText(12));
    range = sheet.getRangeByName('C${row}:K$row');
    range.merge();
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.setText(appProvider.getPostContentText(13));
    range = sheet.getRangeByName('L${row}:M$row');
    range.merge();
    range.cellStyle.bold = true;
    range.cellStyle.fontName = "B Titr";
    range.setText(appProvider.getPostContentText(14));
    range = sheet.getRangeByName('A${row}:M$row');
    range.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    range.cellStyle.borders.all.color = '#000000';

    for (int col = 1; col <= 13; col++) {
      sheet.setColumnWidthInPixels(col, col == 1 ? 150 : 100);
    }
    sheet.setRowHeightInPixels(row, 200);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final Directory? directory = await getTemporaryDirectory();
    final String path =
        '${directory!.path}\\${timestampToShamsi(dateTimestamp()).replaceAll("/", "-")}.xlsx';
    try {
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      OpenFilex.open(path);
    } catch (e) {
      //
    }
  }
}
