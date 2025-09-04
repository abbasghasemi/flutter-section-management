import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/post.dart';
import 'package:section_management/models/post_doc.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/theme.dart';
import 'package:section_management/utility.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  int _selectedDateTs = dateTimestamp();
  List<Post> _posts = [];
  List<PostDoc> _postsDoc = [];
  bool _isCreated = false;
  bool _isEdited = false;
  bool _loading = false;
  int _countOfWarning = 0;
  late AppRestartProvider _appRestart;

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
      _generateProposal(false);
    } else {
      _posts = appProvider.getPostsForDate(_selectedDateTs);
      _countOfWarning =
          appProvider.validateAssignments(_posts, _selectedDateTs);
      setState(() {
        _loading = false;
        _isCreated = true;
        _isEdited = false;
      });
    }
  }

  Future<void> _generateProposal([bool deletePrevious = true]) async {
    if (!_loading)
      setState(() {
        _loading = true;
      });
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (deletePrevious) appProvider.deletePosts(_selectedDateTs);
    final proposals = await appProvider.generateProposal(_selectedDateTs);
    _posts = proposals['posts'] as List<Post>;
    _postsDoc = proposals['postsDoc'] as List<PostDoc>;
    _countOfWarning = proposals['countOfWarning'];
    setState(() {
      _loading = false;
      _isCreated = false;
      _isEdited = false;
    });
  }

  void _confirmProposal() {
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
    final tableRows = <TableRow>[
      TableRow(children: [
        Center(
            child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text("موقعیت"),
        )),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text("پست اول"),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text("پست دوم"),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text("پست سوم"),
          ),
        ),
      ])
    ];
    final theme = CupertinoTheme.of(context);
    _postsDoc.forEach((state) {
      final statePosts = _posts
          .where((post) => post.stateId == state.stateId)
          .toList()
        ..sort((a, b) => a.postNo.compareTo(b.postNo));
      final maxPosts = state.forcesId.length;
      final rowCells = <Widget>[
        Center(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(state.stateName),
        ))
      ];
      for (int i = 0; i < 3; i++) {
        if (i >= maxPosts) {
          rowCells.add(Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('*******'),
            ),
          ));
        } else {
          final post = statePosts.firstWhere(
            (p) => p.postNo == i + 1,
            orElse: () => Post(
              id: null,
              forceId: 0,
              stateId: state.stateId,
              postNo: i + 1,
              postDate: _selectedDateTs,
              stateName: state.stateName,
              stateType: state.stateType,
            ),
          );
          final force =
              post.forceId != 0 ? appProvider.getForceById(post.forceId) : null;
          rowCells.add(Container(
            color: _choiceColor(post, force),
            child: Row(
              children: [
                if (post.warnings != null && post.warnings!.isNotEmpty && force != null)
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
                    backgroundColorActivated: _choiceColorActivated(post, force),
                    onTap: () async {
                      final presentForces = await appProvider.getPresentForces(date: _selectedDateTs);
                      final assignedForceIds =
                          _posts.map((p) => p.forceId).toSet();
                      final availableForces = presentForces
                          .where((f) => !assignedForceIds.contains(f.id))
                          .toList();
                      String searchQuery = '';
                      final newForceId = await showCupertinoModalPopup<int>(
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
                                      borderRadius: BorderRadius.circular(3),
                                      color:
                                          DarkTheme.backgroundColorDeActivated,
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
                                child: const Text('خالی'),
                                onPressed: () => Navigator.pop(context, 0),
                              ),
                              ...availableForces
                                  .where((force) =>
                                      searchQuery.isEmpty ||
                                      '${force.firstName} ${force.lastName}'
                                          .contains(searchQuery))
                                  .map((force) => CupertinoActionSheetAction(
                                        child: Text(
                                            '${force.firstName} ${force.lastName}'),
                                        onPressed: () =>
                                            Navigator.pop(context, force.id),
                                      )),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              child: const Text('لغو'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      );
                      if (newForceId != null && newForceId != post.forceId) {
                        _posts.firstWhere(
                          (p) =>
                              p.stateId == state.stateId && p.postNo == i + 1,
                          orElse: () {
                            _posts.add(Post(
                              id: null,
                              stateId: state.stateId,
                              postNo: i + 1,
                              postDate: _selectedDateTs,
                              stateName: state.stateName,
                              forceId: 0,
                              stateType: state.stateType,
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
                        setState(() {
                          _isEdited = true;
                        });
                      }
                    },
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(force != null
                          ? '${force.firstName} ${force.lastName}'
                          : ''),
                    ),
                  ),
                ),
                if (force != null)
                  CupertinoButton(
                    padding: EdgeInsetsGeometry.zero,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: force.firstName + ' ' + force.lastName));
                    },
                  )
              ],
            ),
          ));
        }
      }
      tableRows.add(TableRow(children: rowCells));
    });
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('لوح پستی - ${timestampToShamsi(_selectedDateTs)}'),
        leading: !_isCreated || _isEdited
            ? Tooltip(
                message: 'تأیید لوح',
                child: CupertinoButton(
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
                          CupertinoDialogAction(
                            child: Text("تأیید لوح"),
                            onPressed: () {
                              _confirmProposal();
                              Navigator.pop(context);
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
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'ایجاد لوح پیشنهادی',
              child: CupertinoButton(
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
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: Text("ایجاد لوح پیشنهادی"),
                            onPressed: () async {
                              await _generateProposal();
                              Navigator.pop(context);
                            },
                          ),
                          CupertinoDialogAction(
                            child: Text("بستن"),
                            onPressed: () => Navigator.pop(context),
                          ),
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
                    _selectedDateTs = date.millisecondsSinceEpoch ~/ 1000;
                    await _loadPosts();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Table(
                border: TableBorder.all(
                  color: DarkTheme.backgroundColorDeActivated,
                  borderRadius: BorderRadius.circular(3),
                ),
                columnWidths: {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                  3: FlexColumnWidth(),
                },
                children: tableRows,
              ),
            ),
            Container(
              child: Column(
                children: [
                  Icon(
                    Icons.error_rounded,
                    color: Colors.red,
                  ),
                  Text(
                    "${_countOfError()} عدد خطا",
                    style: theme.textTheme.actionSmallTextStyle.apply(
                      color: Colors.white,
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
                    "${_countOfWarning-_countOfError()} عدد هشدار",
                    style: theme.textTheme.actionSmallTextStyle.apply(
                      color: Colors.white,
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
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _appRestart.removeListener(_restart);
    super.dispose();
  }

  Color? _choiceColor(Post post, Force? force) {
    if (post.forceId == 0 || force == null) return Colors.white.withAlpha(10);
    if (post.hasError) return Colors.redAccent.withAlpha(30);
    if (post.warnings != null && post.warnings!.isNotEmpty) {
      return Colors.orangeAccent.withAlpha(30);
    }
    return null;
  }

  Color? _choiceColorActivated(Post post, Force? force) {
    if (force == null) return  DarkTheme.backgroundColorActivated;
    if (post.hasError) return Colors.redAccent.withAlpha(200);
    return post.warnings != null && post.warnings!.isNotEmpty
        ? Colors.orangeAccent.withAlpha(200)
        : DarkTheme.backgroundColorActivated;
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
}
