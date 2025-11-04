import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/models/leave_detail.dart';
import 'package:section_management/models/note.dart';
import 'package:section_management/models/state.dart' as model;
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/providers/force_provider.dart';
import 'package:section_management/utility.dart';

class ForcesScreen extends StatefulWidget {
  const ForcesScreen({super.key});

  @override
  State<ForcesScreen> createState() => _ForcesScreenState();
}

class _ForcesScreenState extends State<ForcesScreen> {
  int _offset = 0;
  final int _limit = 313;
  bool _sidebarFilterOpened = false;
  bool _isLoading = false;
  final _searchQuery = ValueNotifier<String>('');
  final _selectedUnitId = ValueNotifier<int?>(null);
  final _canArmedFilter = ValueNotifier<bool?>(null);
  final _endDateFilter = ValueNotifier<int?>(null);
  final _leaveTypeFilter = ValueNotifier<LeaveType?>(null);
  final _leaveDateFilter = ValueNotifier<int?>(null);
  final _presentFilter = ValueNotifier(false);
  List<Force> _filteredForces = [];
  late AppRestartProvider _appRestart;
  late ForceProvider _forceProvider;

  void _restart() {
    _offset = 0;
    _loadForces();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _force_received() {
    Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
          builder: (context) => ForceDetailScreen(
            force: _forceProvider.force,
            updateScreen: _restart,
          ),
        ),
        (r) => r.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _loadForces();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
    _forceProvider = context.read<ForceProvider>();
    _forceProvider.addListener(_force_received);
  }

  Future<void> _loadForces() async {
    if (_isLoading) return;
    _isLoading = true;
    setState(() {});
    if (_presentFilter.value) {
      _filteredForces = await Provider.of<AppProvider>(context, listen: false)
          .getPresentForces(
        limit: _limit,
        offset: _offset,
        date: dateTimestamp(),
        unitIds:
            _selectedUnitId.value != null ? [_selectedUnitId.value!] : null,
      );
    } else {
      _filteredForces =
          await Provider.of<AppProvider>(context, listen: false).filterForces(
        searchQuery: _searchQuery.value,
        unitId: _selectedUnitId.value,
        canArmed: _canArmedFilter.value,
        endDate: _endDateFilter.value,
        leaveDate: _leaveDateFilter.value,
        leaveType: _leaveTypeFilter.value,
        limit: _limit,
        offset: _offset,
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreForces() async {
    if (_isLoading) return;
    _isLoading = true;
    setState(() => _offset += _limit);
    final moreForces =
        await Provider.of<AppProvider>(context, listen: false).filterForces(
      searchQuery: _searchQuery.value,
      unitId: _selectedUnitId.value,
      canArmed: _canArmedFilter.value,
      endDate: _endDateFilter.value,
      leaveDate: _leaveDateFilter.value,
      leaveType: _leaveTypeFilter.value,
      limit: _limit,
      offset: _offset,
    );
    setState(() {
      _filteredForces.addAll(moreForces);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final units = appProvider.units;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: true,
        backgroundColor: AppThemeProvider.backgroundColor,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              mouseCursor: SystemMouseCursors.click,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Icon(CupertinoIcons.chart_bar_fill),
                  const SizedBox(width: 8),
                  Text('فیلتر'),
                ],
              ),
              onPressed: () {
                setState(() {
                  _sidebarFilterOpened = !_sidebarFilterOpened;
                });
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              mouseCursor: SystemMouseCursors.click,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Icon(CupertinoIcons.add),
                  const SizedBox(width: 8),
                  Text('جدید'),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => ForceFormScreen(
                          updateScreen: _restart,
                        )),
              ),
            ),
          ],
        ),
        middle: Text(
          'نیروها (${_filteredForces.length})',
          textAlign: TextAlign.center,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: _sidebarFilterOpened
                    ? Border(
                        left: BorderSide(color: AppThemeProvider.toolbarColor))
                    : null,
                color: AppThemeProvider.backgroundColor,
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 110),
                child: _sidebarFilterOpened
                    ? Container(
                        width: 200,
                        color: AppThemeProvider.backgroundColor,
                        child: Column(
                          children: [
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _selectedUnitId,
                              builder: (context, unitId, _) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                    unitId == null
                                        ? 'واحد: همه'
                                        : 'واحد: ${units.firstWhere((u) => u.id == unitId).name}',
                                    style: theme.textTheme.actionSmallTextStyle
                                        .apply(
                                            color: AppThemeProvider
                                                .textTitleColor),
                                  ),
                                  onTap: () async {
                                    final newUnitId =
                                        await showCupertinoModalPopup<int>(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoActionSheet(
                                        title: Text('انتخاب واحد'),
                                        actions: [
                                          CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('همه'),
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                          ),
                                          ...units.map((unit) =>
                                              CupertinoActionSheetAction(
                                                mouseCursor:
                                                    SystemMouseCursors.click,
                                                child: Text(unit.name),
                                                onPressed: () => Navigator.pop(
                                                    context, unit.id),
                                              )),
                                        ],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                          mouseCursor: SystemMouseCursors.click,
                                          child: Text('لغو'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    );
                                    if (newUnitId != unitId) {
                                      _selectedUnitId.value = newUnitId;
                                      _offset = 0;
                                      _filteredForces = [];
                                      _loadForces();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _canArmedFilter,
                              builder: (context, canArmed, _) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                    'مسلح: ${canArmed == null ? 'همه' : canArmed ? 'بله' : 'خیر'}',
                                    style: theme.textTheme.actionSmallTextStyle
                                        .apply(
                                            color: AppThemeProvider
                                                .textTitleColor),
                                  ),
                                  onTap: () async {
                                    final newCanArmed =
                                        await showCupertinoModalPopup<bool>(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoActionSheet(
                                        title: Text('انتخاب وضعیت مسلح'),
                                        actions: [
                                          CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('همه'),
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                          ),
                                          CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('بله'),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                          ),
                                          CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('خیر'),
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                          ),
                                        ],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                          mouseCursor: SystemMouseCursors.click,
                                          child: Text('لغو'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    );
                                    if (newCanArmed != canArmed) {
                                      _canArmedFilter.value = newCanArmed;
                                      _offset = 0;
                                      _filteredForces = [];
                                      _loadForces();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _endDateFilter,
                              builder: (context, endDate, _) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                    'تاریخ تسویه: ${endDate == null ? '-' : timestampToShamsi(endDate)}',
                                    style: theme.textTheme.actionSmallTextStyle
                                        .apply(
                                            color: AppThemeProvider
                                                .textTitleColor),
                                  ),
                                  onTap: () async {
                                    final date = await showPersianDatePicker(
                                      context: context,
                                      initialDate: Jalali.now(),
                                      firstDate: Jalali.now().add(years: -1),
                                      lastDate: Jalali.now().add(years: 1),
                                    );
                                    final newEndDate = date == null
                                        ? null
                                        : date.millisecondsSinceEpoch ~/ 1000;
                                    if (newEndDate != endDate) {
                                      _endDateFilter.value = newEndDate;
                                      _offset = 0;
                                      _filteredForces = [];
                                      _loadForces();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _leaveTypeFilter,
                              builder: (context, leaveType, _) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                    'نوع مرخصی: ${leaveType == null ? 'همه' : leaveType.fa}',
                                    style: theme.textTheme.actionSmallTextStyle
                                        .apply(
                                            color: AppThemeProvider
                                                .textTitleColor),
                                  ),
                                  onTap: () async {
                                    final newLeaveType =
                                        await showCupertinoModalPopup<
                                            LeaveType>(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoActionSheet(
                                        title: Text('انتخاب نوع مرخصی'),
                                        actions: [
                                          CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('همه'),
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                          ),
                                          ...LeaveType.values.map((type) =>
                                              CupertinoActionSheetAction(
                                                mouseCursor:
                                                    SystemMouseCursors.click,
                                                child: Text(type.fa),
                                                onPressed: () => Navigator.pop(
                                                    context, type),
                                              )),
                                        ],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                          mouseCursor: SystemMouseCursors.click,
                                          child: Text('لغو'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    );
                                    if (newLeaveType != leaveType) {
                                      _leaveTypeFilter.value = newLeaveType;
                                      _leaveDateFilter.value = null;
                                      _presentFilter.value = false;
                                      _offset = 0;
                                      _filteredForces = [];
                                      _loadForces();
                                    }
                                  },
                                ),
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: _leaveTypeFilter,
                              builder: (context, leaveType, _) =>
                                  ValueListenableBuilder(
                                valueListenable: _leaveDateFilter,
                                builder: (context, leaveDate, _) => MouseRegion(
                                  cursor: leaveType == null
                                      ? SystemMouseCursors.alias
                                      : SystemMouseCursors.click,
                                  child: CupertinoListTile(
                                    backgroundColorActivated: AppThemeProvider
                                        .backgroundColorActivated,
                                    title: Text(
                                      leaveDate != null
                                          ? timestampToShamsi(leaveDate)
                                          : 'تاریخ مرخصی: -',
                                      style: theme
                                          .textTheme.actionSmallTextStyle
                                          .apply(
                                              color: leaveType == null
                                                  ? Colors.grey
                                                  : AppThemeProvider
                                                      .textTitleColor),
                                    ),
                                    onTap: leaveType == null
                                        ? null
                                        : () async {
                                            final date =
                                                await showPersianDatePicker(
                                              context: context,
                                              initialDate: Jalali.now(),
                                              firstDate:
                                                  Jalali.now().add(years: -1),
                                              lastDate:
                                                  Jalali.now().add(years: 1),
                                            );
                                            final newLeaveDate = date == null
                                                ? null
                                                : date.millisecondsSinceEpoch ~/
                                                    1000;
                                            if (newLeaveDate != leaveDate) {
                                              _leaveDateFilter.value =
                                                  newLeaveDate;
                                              _offset = 0;
                                              _filteredForces = [];
                                              _loadForces();
                                            }
                                          },
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _presentFilter,
                              builder: (context, present, _) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'حاضرین',
                                        style: theme
                                            .textTheme.actionSmallTextStyle
                                            .apply(
                                                color: AppThemeProvider
                                                    .textTitleColor),
                                      ),
                                      SizedBox(
                                        width: 20,
                                        child: Transform.scale(
                                          scale: .7,
                                          child: CupertinoSwitch(
                                            mouseCursor:
                                                SwitchWidgetStateProperty(),
                                            value: present,
                                            onChanged: (value) {
                                              _leaveTypeFilter.value = null;
                                              _leaveDateFilter.value = null;
                                              _offset = 0;
                                              _filteredForces = [];
                                              _presentFilter.value = value;
                                              _loadForces();
                                            },
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  onTap: () {
                                    _leaveTypeFilter.value = null;
                                    _leaveDateFilter.value = null;
                                    _offset = 0;
                                    _filteredForces = [];
                                    _presentFilter.value = !present;
                                    _loadForces();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 8, bottom: 10, top: 8),
                    child: CupertinoSearchTextField(
                      decoration: BoxDecoration(
                          color: AppThemeProvider.backgroundColorDeActivated),
                      placeholder: 'جستجو بر اساس کد ملی یا نام',
                      onChanged: (value) {
                        setState(() {
                          _searchQuery.value = value;
                          _offset = 0;
                          _filteredForces = [];
                          _loadForces();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (!_isLoading &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 200) {
                          _loadMoreForces();
                        }
                        return false;
                      },
                      child: _isLoading && _filteredForces.isEmpty
                          ? Center(child: CupertinoActivityIndicator())
                          : _filteredForces.isEmpty
                              ? Center(
                                  child: Text(
                                    'نیرویی یافت نشد',
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      EdgeInsets.only(bottom: 10, right: 5),
                                  itemCount: _filteredForces.length +
                                      (_isLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _filteredForces.length) {
                                      return Center(
                                          child: CupertinoActivityIndicator());
                                    }
                                    final force = _filteredForces[index];
                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: CupertinoListTile(
                                          leadingToTitle: 5,
                                          backgroundColorActivated:
                                              AppThemeProvider
                                                  .backgroundColorActivated,
                                          backgroundColor: index % 2 == 0
                                              ? AppThemeProvider
                                                  .backgroundSecondaryColor
                                              : Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          leading: Text('${index + 1}'),
                                          title: Text(
                                              '${force.firstName} ${force.lastName} (${force.fatherName})'),
                                          subtitle: Text(
                                              'کد ملی: ${force.codeMeli} - ${force.unitName}${force.codeId.isNotEmpty ? ' - کد پرونده: ${force.codeId}' : ''}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FutureBuilder(
                                                future: appProvider
                                                    .getForceInfo(force.id!),
                                                builder: (context, snap) {
                                                  if (!snap.hasData) {
                                                    return CupertinoActivityIndicator();
                                                  }
                                                  final leave = snap.data![
                                                              'lastDateLeave'] ==
                                                          0
                                                      ? force.createdDate
                                                      : snap.data![
                                                          'lastDateLeave']!;
                                                  final days = Jalali
                                                          .fromMillisecondsSinceEpoch(
                                                              leave * 1000)
                                                      .distanceTo(Jalali.now());
                                                  return Column(
                                                    children: [
                                                      Text(
                                                        "${snap.data!['postsCount']} پست",
                                                        style: theme.textTheme
                                                            .actionSmallTextStyle,
                                                      ),
                                                      Text(
                                                        "${days} روز",
                                                        style: theme.textTheme
                                                            .actionSmallTextStyle,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: const Icon(
                                                    CupertinoIcons.forward),
                                              ),
                                            ],
                                          ),
                                          onTap: () => Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) =>
                                                      ForceDetailScreen(
                                                          force: force,
                                                          updateScreen:
                                                              _restart),
                                                ),
                                              )),
                                    );
                                  },
                                ),
                    ),
                  ),
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
    _searchQuery.dispose();
    _selectedUnitId.dispose();
    _canArmedFilter.dispose();
    _endDateFilter.dispose();
    _leaveTypeFilter.dispose();
    _leaveDateFilter.dispose();
    _presentFilter.dispose();
    _appRestart.removeListener(_restart);
    _forceProvider.removeListener(_force_received);
    super.dispose();
  }
}

class ForceDetailScreen extends StatelessWidget {
  final Force force;
  final Function() updateScreen;

  const ForceDetailScreen(
      {super.key, required this.force, required this.updateScreen});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final daysOffText =
        force.daysOff == -1 ? 'همیشه' : force.daysOff.toString();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${force.firstName} ${force.lastName}'),
        leading: CupertinoPageBack(
          previousPageTitle: 'نیروها',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'ویرایش نیرو',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.pencil),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ForceFormScreen(
                      force: force,
                      updateScreen: updateScreen,
                    ),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'افزودن یادداشت',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.doc_text),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AddNoteScreen(
                      forceId: force.id!,
                      name: force.firstName + " " + force.lastName,
                    ),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'ثبت مرخصی',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.calendar_badge_minus),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ForceLeaveFormScreen(
                        forceId: force.id!,
                        name: force.firstName + " " + force.lastName),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'حذف نیرو',
              child: CupertinoButton(
                mouseCursor: SystemMouseCursors.click,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.delete),
                onPressed: () async {
                  final confirmed = await showCupertinoDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('حذف نیرو'),
                      content: Text(
                          'آیا از حذف ${force.firstName} ${force.lastName} مطمئن هستید؟'),
                      actions: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CupertinoDialogAction(
                            child: const Text('لغو'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('حذف'),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed) {
                    appProvider.deleteForce(force.id!);
                    updateScreen.call();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: AppThemeProvider.backgroundColorDeActivated),
              backgroundColor: AppThemeProvider.backgroundColor,
              header: const Text('اطلاعات نیرو'),
              children: [
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('کد ملی: ${force.codeMeli}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('کد پرونده: ${force.codeId}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('نام: ${force.firstName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('نام خانوادگی: ${force.lastName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('نام پدر: ${force.fatherName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('بومی: ${force.isNative ? 'بله' : 'خیر'}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('تاهل: ${force.isMarried ? 'متاهل' : 'مجرد'}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('مسلح: ${force.canArmed ? 'بله' : 'خیر'}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('واحد: ${force.unitName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('مسئولیت: ${force.stateType.fa}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('روزهای استراحت: $daysOffText')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Builder(builder: (context) {
                      final workdays = List.generate(
                          7,
                          (index) => (force.workdays & (1 << index)) != 0
                              ? nameOfWeek(index)
                              : '').where((a) => a.isNotEmpty);
                      if (workdays.isEmpty) {
                        return Text('روزهای کاری: ندارد');
                      }
                      return Text(
                          'روزهای کاری: ${workdays.length != 7 ? workdays.join(' ,') : 'تمامی ایام هفته'}');
                    })),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('شماره تلفن: ${force.phoneNo}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text(
                        'تاریخ معرفی: ${timestampToShamsi(force.createdDate)} تاریخ تسویه: ${timestampToShamsi(force.endDate)}')),
                FutureBuilder(
                    future: appProvider.getLastDateLeave(force.id!),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return Container();
                      }
                      final leave =
                          snap.data == 0 ? force.createdDate : snap.data!;
                      final days =
                          Jalali.fromMillisecondsSinceEpoch(leave * 1000)
                              .distanceTo(Jalali.now());
                      final value =
                          (days / 30) * appProvider.getMultiplierOfTheMonth();
                      return CupertinoListTile(
                          backgroundColorActivated:
                              AppThemeProvider.backgroundColorActivated,
                          title: Text('استحقاق: ${value.toStringAsFixed(2)}'));
                    }),
              ],
            ),
            FutureBuilder(
              future: appProvider.getLeavesByForceId(force.id!),
              builder: (context, data) {
                if (data.hasData) {
                  final leaves = data.data!;
                  return CupertinoListSection(
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated),
                    backgroundColor: AppThemeProvider.backgroundColor,
                    header: const Text('مرخصی‌ها/غیبت‌ها'),
                    children: leaves.isEmpty
                        ? [
                            CupertinoListTile(
                                backgroundColorActivated:
                                    AppThemeProvider.backgroundColorActivated,
                                title: Text('موردی موجود نیست'))
                          ]
                        : leaves.map((leave) {
                            final List<LeaveDetail> details = leave.details;
                            final detailsText = details.isNotEmpty
                                ? details.map((d) {
                                    if (d.title is HourlyType) {
                                      return '${d.days} ساعت';
                                    }
                                    return '${d.fa}: ${d.days} روز';
                                  }).join(', ')
                                : 'بدون جزئیات';
                            return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text('${leave.leaveType.fa}'),
                                  subtitle: Text(
                                    leave.leaveType == LeaveType.hourly
                                        ? '${timestampToShamsi(leave.fromDate)} - $detailsText'
                                        : 'از ${timestampToShamsi(leave.fromDate)} تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'} - $detailsText',
                                  ),
                                  trailing: const Icon(CupertinoIcons.pencil),
                                  onTap: () => Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          ForceLeaveFormScreen(
                                              forceId: force.id!,
                                              name: force.firstName +
                                                  " " +
                                                  force.lastName,
                                              leave: leave),
                                    ),
                                  ),
                                ));
                          }).toList(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              },
            ),
            FutureBuilder(
              future: appProvider.getNotesByForceId(force.id!),
              builder: (context, data) {
                if (data.hasData) {
                  final notes = data.data!;
                  return CupertinoListSection(
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated),
                    backgroundColor: AppThemeProvider.backgroundColor,
                    header: const Text('یادداشت‌ها'),
                    children: notes.isEmpty
                        ? [
                            CupertinoListTile(
                                backgroundColorActivated:
                                    AppThemeProvider.backgroundColorActivated,
                                title: Text('یادداشتی موجود نیست'))
                          ]
                        : notes
                            .map((note) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoListTile(
                                  onTap: () {
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoAlertDialog(
                                        title: Text(
                                            timestampToShamsi(note.noteDate)),
                                        content: Text(note.note),
                                        actions: [
                                          MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoDialogAction(
                                                child: Text('بستن'),
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                              )),
                                        ],
                                      ),
                                    );
                                  },
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                    note.note.replaceAll("\n", ' '),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .actionSmallTextStyle
                                        .apply(
                                            color: AppThemeProvider
                                                .textTitleColor),
                                  ),
                                  subtitle:
                                      Text(timestampToShamsi(note.noteDate)),
                                )))
                            .toList(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              },
            ),
            FutureBuilder(
              future: appProvider.getPostsByForceId(force.id!),
              builder: (context, data) {
                if (data.hasData) {
                  final posts = data.data!;
                  return CupertinoListSection(
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated),
                    backgroundColor: AppThemeProvider.backgroundColor,
                    header: Text('پست‌ها (${posts.length})'),
                    children: [
                      Column(
                        children: posts.isEmpty
                            ? [
                                CupertinoListTile(
                                    backgroundColorActivated: AppThemeProvider
                                        .backgroundColorActivated,
                                    title: Text('پستی موجود نیست'))
                              ]
                            : posts.map((post) {
                                final state = appProvider.states.firstWhere(
                                  (s) => s.id == post.stateId,
                                  orElse: () => model.State(
                                    id: null,
                                    name: 'نامشخص',
                                    isActive: false,
                                    isArmed: false,
                                    stateType: StateType.post,
                                    unitId: 0,
                                  ),
                                );
                                return CupertinoListTile(
                                  backgroundColorActivated:
                                      AppThemeProvider.backgroundColorActivated,
                                  title: Text(
                                      '${state.name} - پست ${post.postNo}'),
                                  subtitle:
                                      Text(timestampToShamsi(post.postDate)),
                                );
                              }).toList(),
                      ),
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ForceLeaveFormScreen extends StatefulWidget {
  final Leave? leave;
  final int forceId;
  final String name;

  const ForceLeaveFormScreen(
      {super.key, this.leave, required this.forceId, required this.name});

  @override
  State<ForceLeaveFormScreen> createState() => _ForceLeaveFormScreenState();
}

class _ForceLeaveFormScreenState extends State<ForceLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ValueNotifier<int> _fromDate;
  late ValueNotifier<int?> _toDate;
  late ValueNotifier<LeaveType> _leaveType;
  late ValueNotifier<List<LeaveDetail>> _details;

  @override
  void initState() {
    super.initState();
    _fromDate = ValueNotifier(widget.leave?.fromDate ?? dateTimestamp());
    _toDate = ValueNotifier(widget.leave?.toDate);
    _leaveType = ValueNotifier(widget.leave?.leaveType ?? LeaveType.presence);
    _details = ValueNotifier(widget.leave?.details ??
        [
          LeaveDetail(title: PresenceType.merit, days: 0),
          LeaveDetail(title: PresenceType.days_off, days: 2)
        ]);
  }

  @override
  void dispose() {
    _fromDate.dispose();
    _toDate.dispose();
    _leaveType.dispose();
    _details.dispose();
    super.dispose();
  }

  List<Enum> _getDetailsType() {
    if (_leaveType.value == LeaveType.presence) {
      return PresenceType.values;
    } else if (_leaveType.value == LeaveType.mission) {
      return MissionType.values;
    } else if (_leaveType.value == LeaveType.hourly) {
      return HourlyType.values;
    } else if (_leaveType.value == LeaveType.sick) {
      return SickType.values;
    } else {
      return DetentionType.values;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text((widget.leave == null ? 'ثبت مرخصی' : 'ویرایش مرخصی') +
            " - " +
            widget.name),
        leading: CupertinoPageBack(
          previousPageTitle: 'بازگشت',
        ),
        trailing: widget.leave != null
            ? Tooltip(
                message: 'حذف',
                child: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.delete,
                      color: CupertinoColors.destructiveRed),
                  onPressed: () async {
                    final confirmed = await showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text('حذف مرخصی'),
                        content: Text('آیا از حذف این مرخصی مطمئن هستید؟'),
                        actions: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: CupertinoDialogAction(
                              child: Text('لغو'),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: Text('حذف',
                                  style: TextStyle(
                                      color: CupertinoColors.destructiveRed)),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed) {
                      final leave = widget.leave!;
                      appProvider.deleteLeave(leave.id!);
                      appProvider.addNote(
                          widget.forceId,
                          'حذف ${leave.leaveType.fa}: از ${timestampToShamsi(leave.fromDate)} '
                          'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}، '
                          'جزئیات: ${leave.details.map((d) => "${d.fa} (${d.days} روز)").join(', ')}',
                          0);
                      Navigator.pop(context);
                    }
                  },
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ValueListenableBuilder(
                valueListenable: _leaveType,
                builder: (context, leaveType, _) => CupertinoListTile(
                  title: Text('نوع مرخصی: ${leaveType.fa}'),
                  trailing: CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    child: Text('انتخاب مرخصی'),
                    onPressed: () async {
                      final newLeaveType =
                          await showCupertinoModalPopup<LeaveType>(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: Text('انتخاب مرخصی'),
                          actions: LeaveType.values
                              .map((type) => CupertinoActionSheetAction(
                                    mouseCursor: SystemMouseCursors.click,
                                    child: Text(type.fa),
                                    onPressed: () =>
                                        Navigator.pop(context, type),
                                  ))
                              .toList(),
                          cancelButton: CupertinoActionSheetAction(
                            mouseCursor: SystemMouseCursors.click,
                            child: Text('لغو'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      );
                      if (newLeaveType != null && newLeaveType != leaveType) {
                        _leaveType.value = newLeaveType;
                        if (newLeaveType == LeaveType.hourly) {
                          _toDate.value = _fromDate.value;
                        }
                        if (newLeaveType == LeaveType.presence) {
                          _details.value = [
                            LeaveDetail(
                                title: (_getDetailsType().first), days: 0),
                            LeaveDetail(title: PresenceType.days_off, days: 2)
                          ];
                        } else if (newLeaveType == LeaveType.detention) {
                          _details.value = [
                            LeaveDetail(
                                title: (_getDetailsType().first), days: 0),
                            LeaveDetail(title: DetentionType.days_off, days: 1)
                          ];
                        } else {
                          _details.value = [
                            LeaveDetail(
                                title: (_getDetailsType().first), days: 0)
                          ];
                        }
                      }
                    },
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _fromDate,
                builder: (context, fromDate, _) => CupertinoListTile(
                  title: Text('از تاریخ: ${timestampToShamsi(fromDate)}'),
                  trailing: CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    child: Text('انتخاب تاریخ'),
                    onPressed: () async {
                      final date = await showPersianDatePicker(
                        context: context,
                        initialDate: Jalali.now(),
                        firstDate: Jalali.now().add(years: -1),
                        lastDate: Jalali.now().add(years: 1),
                      );
                      if (date != null &&
                          date.millisecondsSinceEpoch ~/ 1000 !=
                              _fromDate.value) {
                        _fromDate.value = date.millisecondsSinceEpoch ~/ 1000;
                      }
                      if (date != null) {
                        _selectEndDate(context);
                      }
                    },
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _toDate,
                builder: (context, toDate, _) => CupertinoListTile(
                  title: Text(
                    'تا تاریخ: ${toDate != null ? timestampToShamsi(toDate) : 'نامشخص'}',
                  ),
                  trailing: CupertinoButton(
                    mouseCursor: SystemMouseCursors.click,
                    child: Text('انتخاب تاریخ'),
                    onPressed: () => _selectEndDate(context),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _details,
                builder: (context, details, _) => Column(
                  children: details.asMap().entries.map((entry) {
                    final index = entry.key;
                    final detail = entry.value;
                    return Row(
                      children: [
                        if (details.length > 1)
                          CupertinoButton(
                            mouseCursor: SystemMouseCursors.click,
                            minimumSize: Size(24, 24),
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(CupertinoIcons.minus_circle,
                                color: CupertinoColors.destructiveRed),
                            onPressed: () => _details.value = List.from(details)
                              ..removeAt(index),
                          ),
                        SizedBox(
                          width:
                              _leaveType.value == LeaveType.hourly ? 140 : 130,
                          child: CupertinoTextFormFieldRow(
                            maxLength:
                                _leaveType.value == LeaveType.hourly ? 1 : 2,
                            maxLines: 1,
                            initialValue: detail.days.toString(),
                            prefix: Text(
                                'تعداد ${_leaveType.value == LeaveType.hourly ? "ساعت" : "روز"}  '),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: CupertinoColors.systemGrey),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                _details.value = List.from(details)
                                  ..[index] = LeaveDetail(
                                      title: detail.title,
                                      days: int.tryParse(value) ?? 0),
                            validator: (value) {
                              if (value!.isNotEmpty) {
                                if (_leaveType.value == LeaveType.hourly) {
                                  if (value > '7') {
                                    return 'بیش از 7 ساعت قابل ثبت نیست';
                                  }
                                }
                                return null;
                              }
                              if (_leaveType.value == LeaveType.hourly) {
                                return 'تعداد ساعت الزامی است';
                              }
                              return 'تعداد روز الزامی است';
                            },
                          ),
                        ),
                        Expanded(
                          child: CupertinoListTile(
                            title: Text('عنوان: ${detail.fa}'),
                            trailing: !_checkAllowAddBtn(details.length)
                                ? null
                                : CupertinoButton(
                                    mouseCursor: SystemMouseCursors.click,
                                    child: Text('انتخاب عنوان'),
                                    onPressed: () async {
                                      final title =
                                          await showCupertinoModalPopup<Enum>(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoActionSheet(
                                          title: Text('انتخاب عنوان'),
                                          actions: _getDetailsType()
                                              .where((e) => !details
                                                  .any((d) => d.title == e))
                                              .map((t) =>
                                                  CupertinoActionSheetAction(
                                                    mouseCursor:
                                                        SystemMouseCursors
                                                            .click,
                                                    child:
                                                        Text((t as FaName).fa),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, t),
                                                  ))
                                              .toList(),
                                          cancelButton:
                                              CupertinoActionSheetAction(
                                            mouseCursor:
                                                SystemMouseCursors.click,
                                            child: Text('لغو'),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      );
                                      if (title != null) {
                                        _details.value = List.from(details)
                                          ..[index] = LeaveDetail(
                                              title: title, days: detail.days);
                                      }
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              ValueListenableBuilder(
                  valueListenable: _details,
                  builder: (context, value, child) {
                    if (!_checkAllowAddBtn(value.length)) return Container();
                    return CupertinoButton(
                      mouseCursor: SystemMouseCursors.click,
                      child: Text('افزودن عنوان'),
                      onPressed: () {
                        for (var e in _getDetailsType()) {
                          if (!value.any((d) => d.title == e)) {
                            _details.value = List.from(value)
                              ..add(LeaveDetail(title: e, days: 0));
                            break;
                          }
                        }
                      },
                    );
                  }),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CupertinoButton.filled(
                  mouseCursor: SystemMouseCursors.click,
                  child: Text(widget.leave == null ? 'ثبت' : 'ذخیره'),
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _details.value.every((d) => d.days > 0) &&
                        (_toDate.value != null ||
                            _leaveType.value == LeaveType.sick ||
                            _leaveType.value == LeaveType.absent)) {
                      final leave = Leave(
                        id: widget.leave?.id,
                        forceId: widget.forceId,
                        fromDate: _fromDate.value,
                        toDate: _toDate.value,
                        leaveType: _leaveType.value,
                        details: _details.value,
                      );
                      try {
                        if (widget.leave == null) {
                          appProvider.addLeave(leave);
                        } else {
                          final changes = widget.leave!
                              .compareChanges(leave, timestampToShamsi);
                          if (changes.isNotEmpty) {
                            appProvider.updateLeave(leave.id!, leave);
                            appProvider.addNote(
                                widget.forceId, 'تغییرات مرخصی: $changes', 0);
                          }
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: Text('خطا'),
                            content: Text(e.toString()),
                            actions: [
                              MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: CupertinoDialogAction(
                                    child: Text('تأیید'),
                                    onPressed: () => Navigator.pop(context),
                                  )),
                            ],
                          ),
                        );
                      }
                    } else {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text('خطا'),
                          content: Text(
                              'لطفاً تمام فیلدهای الزامی را پر کنید و تعداد روز‌ها را مشخص کنید'),
                          actions: [
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoDialogAction(
                                  child: Text('تأیید'),
                                  onPressed: () => Navigator.pop(context),
                                )),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromMillisecondsSinceEpoch(_fromDate.value * 1000),
      firstDate: Jalali.fromMillisecondsSinceEpoch(_fromDate.value * 1000),
      lastDate: Jalali.fromMillisecondsSinceEpoch(_fromDate.value * 1000)
          .add(years: 1),
    );
    _toDate.value = date == null ? null : date.millisecondsSinceEpoch ~/ 1000;
  }

  bool _checkAllowAddBtn(int length) {
    if (_leaveType.value == LeaveType.hourly) {
      return false;
    }
    if (_leaveType.value == LeaveType.presence && length >= 4) {
      return false;
    }
    if ((_leaveType.value == LeaveType.sick ||
            _leaveType.value == LeaveType.mission) &&
        length >= 2) {
      return false;
    }
    if (length >= 3 && _leaveType.value != LeaveType.presence) {
      return false;
    }
    return true;
  }
}

class ForceFormScreen extends StatefulWidget {
  final Force? force;
  final Function() updateScreen;

  const ForceFormScreen({super.key, this.force, required this.updateScreen});

  @override
  State<ForceFormScreen> createState() => _ForceFormScreenState();
}

class _ForceFormScreenState extends State<ForceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeMeliController;
  late TextEditingController _codeIdController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _phoneNoController;
  late bool _isNative;
  late bool _isMarried;
  late int _startDate;
  late int _endDate;
  late bool _canArmed;
  late int _unitId;
  late int _daysOff;
  late ValueNotifier<bool> _alwaysOff;
  late int _workdays;
  late StateType _stateType;

  @override
  void initState() {
    super.initState();
    _codeMeliController =
        TextEditingController(text: widget.force?.codeMeli ?? '');
    _codeIdController = TextEditingController(text: widget.force?.codeId ?? '');
    _firstNameController =
        TextEditingController(text: widget.force?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.force?.lastName ?? '');
    _fatherNameController =
        TextEditingController(text: widget.force?.fatherName ?? '');
    _phoneNoController =
        TextEditingController(text: widget.force?.phoneNo.toString() ?? '');
    _isNative = widget.force?.isNative ?? false;
    _isMarried = widget.force?.isMarried ?? false;
    _startDate = widget.force?.createdDate ?? dateTimestamp();
    _endDate = widget.force?.endDate ?? dateTimestamp();
    _canArmed = widget.force?.canArmed ?? true;
    _unitId = widget.force?.unitId ?? 1;
    _daysOff = widget.force?.daysOff ?? 1;
    _alwaysOff = ValueNotifier(_daysOff == -1);
    if (_alwaysOff.value) {
      _daysOff = 1;
    }
    _workdays = widget.force?.workdays ?? 127;
    _stateType = widget.force?.stateType ?? StateType.post;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final units = appProvider.units;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoPageBack(
          previousPageTitle: widget.force == null ? 'نیروها' : 'بازگشت',
        ),
        middle: Text(widget.force == null ? 'افزودن نیرو' : 'ویرایش نیرو'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              CupertinoTextFormFieldRow(
                autofocus: true,
                controller: _codeMeliController,
                prefix: Text('کد ملی              '),
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: (value) =>
                    value!.length != 10 ? 'کد ملی الزامی است' : null,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoTextFormFieldRow(
                controller: _firstNameController,
                prefix: Text('نام                     '),
                validator: (value) => value!.isEmpty ? 'نام الزامی است' : null,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoTextFormFieldRow(
                controller: _lastNameController,
                prefix: Text('نام خانوادگی      '),
                validator: (value) =>
                    value!.isEmpty ? 'نام خانوادگی الزامی است' : null,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoTextFormFieldRow(
                controller: _fatherNameController,
                prefix: Text('نام پدر                '),
                validator: (value) =>
                    value!.isEmpty ? 'نام پدر الزامی است' : null,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoTextFormFieldRow(
                controller: _phoneNoController,
                prefix: Text('شماره تلفن         '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
                validator: (value) =>
                    value!.isEmpty ? 'شماره تلفن الزامی است' : null,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoTextFormFieldRow(
                controller: _codeIdController,
                prefix: Text('کد پرونده            '),
                maxLength: 10,
                validator: (value) {
                  if (value == null) return null;
                  return value.isEmpty &&
                          widget.force != null &&
                          widget.force!.codeId != ''
                      ? 'کد پرونده الزامی است'
                      : null;
                },
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              ValueListenableBuilder(
                  valueListenable: _alwaysOff,
                  builder: (context, alwaysOff, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: alwaysOff
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0, horizontal: 8),
                                  child: Text('روزهای استراحت: همیشه'),
                                )
                              : CupertinoTextFormFieldRow(
                                  prefix: Text('روزهای استراحت '),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  initialValue: _daysOff.toString(),
                                  maxLength: 2,
                                  onChanged: (value) => setState(() =>
                                      _daysOff = int.tryParse(value) ?? 0),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'روزهای استراحت الزامی است';
                                    } else if (int.parse(value) >= 0 &&
                                        int.parse(value) <= 30) {
                                      return null;
                                    }
                                    return 'عددی بین 0 تا 30 وارد کنید';
                                  },
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CupertinoColors.systemGrey),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 12.0),
                                ),
                        ),
                        CupertinoSwitch(
                            mouseCursor: SwitchWidgetStateProperty(),
                            value: alwaysOff,
                            onChanged: (_) {
                              _alwaysOff.value = !alwaysOff;
                            }),
                        SizedBox(
                          width: 8,
                        ),
                      ],
                    );
                  }),
              WeekdayPicker(
                  initialBitmask: _workdays,
                  onChange: (mask) => _workdays = mask),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('بومی: ${_isNative ? 'بله' : 'خیر'}'),
                trailing: CupertinoSwitch(
                  mouseCursor: SwitchWidgetStateProperty(),
                  value: _isNative,
                  onChanged: (value) => setState(() => _isNative = value),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('تاهل: ${_isMarried ? 'متاهل' : 'مجرد'}'),
                trailing: CupertinoSwitch(
                  mouseCursor: SwitchWidgetStateProperty(),
                  value: _isMarried,
                  onChanged: (value) => setState(() => _isMarried = value),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('مسلح: ${_canArmed ? 'بله' : 'خیر'}'),
                trailing: CupertinoSwitch(
                  mouseCursor: SwitchWidgetStateProperty(),
                  value: _canArmed,
                  onChanged: (value) => setState(() => _canArmed = value),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('تاریخ معرفی: ${timestampToShamsi(_startDate)}'),
                trailing: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  child: const Text('انتخاب تاریخ'),
                  onPressed: () async {
                    final date = await showPersianDatePicker(
                      context: context,
                      initialDate: Jalali.now(),
                      firstDate: Jalali.now().add(years: -10),
                      lastDate: Jalali.now().add(years: 10),
                    );
                    if (date != null) {
                      setState(() =>
                          _startDate = date.millisecondsSinceEpoch ~/ 1000);
                    }
                  },
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('تاریخ تسویه: ${timestampToShamsi(_endDate)}'),
                trailing: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  child: const Text('انتخاب تاریخ'),
                  onPressed: () async {
                    final date = await showPersianDatePicker(
                      context: context,
                      initialDate: Jalali.now(),
                      firstDate: Jalali.now().add(years: -10),
                      lastDate: Jalali.now().add(years: 10),
                    );
                    if (date != null) {
                      setState(
                          () => _endDate = date.millisecondsSinceEpoch ~/ 1000);
                    }
                  },
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text(
                    'واحد: ${units.firstWhere((u) => u.id == _unitId).name}'),
                trailing: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  child: const Text('انتخاب واحد'),
                  onPressed: () async {
                    final unitId = await showCupertinoModalPopup<int>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text('انتخاب واحد'),
                        actions: units
                            .map((unit) => CupertinoActionSheetAction(
                                  mouseCursor: SystemMouseCursors.click,
                                  child: Text(unit.name),
                                  onPressed: () =>
                                      Navigator.pop(context, unit.id),
                                ))
                            .toList(),
                        cancelButton: CupertinoActionSheetAction(
                          mouseCursor: SystemMouseCursors.click,
                          child: const Text('لغو'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    );
                    if (unitId != null) {
                      setState(() => _unitId = unitId);
                    }
                  },
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: Text('مسئولیت: ${_stateType.fa}'),
                trailing: CupertinoButton(
                  mouseCursor: SystemMouseCursors.click,
                  child: const Text('انتخاب مسئولیت'),
                  onPressed: () async {
                    final stateType = await showCupertinoModalPopup<StateType>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text('انتخاب مسئولیت'),
                        actions: StateType.values
                            .map((type) => CupertinoActionSheetAction(
                                  mouseCursor: SystemMouseCursors.click,
                                  child: Text(type.fa),
                                  onPressed: () => Navigator.pop(context, type),
                                ))
                            .toList(),
                        cancelButton: CupertinoActionSheetAction(
                          mouseCursor: SystemMouseCursors.click,
                          child: const Text('لغو'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    );
                    if (stateType != null) {
                      setState(() => _stateType = stateType);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CupertinoButton.filled(
                  mouseCursor: SystemMouseCursors.click,
                  child: Text(widget.force == null ? 'افزودن' : 'ذخیره'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final force = Force(
                        id: widget.force?.id,
                        codeMeli: _codeMeliController.text,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        fatherName: _fatherNameController.text.trim(),
                        isNative: _isNative,
                        isMarried: _isMarried,
                        endDate: _endDate,
                        createdDate: _startDate,
                        deletedDate: null,
                        canArmed: _canArmed,
                        unitId: _unitId,
                        daysOff: _alwaysOff.value ? -1 : _daysOff,
                        workdays: _workdays,
                        unitName: widget.force?.unitName ??
                            units.firstWhere((i) => i.id == _unitId).name,
                        phoneNo: int.tryParse(_phoneNoController.text) ?? 0,
                        stateType: _stateType,
                        codeId: _codeIdController.text.trim(),
                      );
                      final appProvider =
                          Provider.of<AppProvider>(context, listen: false);
                      try {
                        if (widget.force == null) {
                          appProvider.addForce(force);
                        } else {
                          appProvider.updateForce(widget.force!, force);
                        }
                        widget.updateScreen.call();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      } catch (e) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('نیروی تکراری'),
                            content: Text('کد ملی وارد شده، قبلا ثبت شده است'),
                            actions: [
                              MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: CupertinoDialogAction(
                                    child: const Text('تأیید'),
                                    onPressed: () => Navigator.pop(context),
                                  )),
                            ],
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeMeliController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fatherNameController.dispose();
    _phoneNoController.dispose();
    super.dispose();
  }
}

class AddNoteScreen extends StatefulWidget {
  final int forceId;
  final String name;

  const AddNoteScreen({super.key, required this.forceId, required this.name});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('افزودن یادداشت - ${widget.name}'),
        leading: CupertinoPageBack(
          previousPageTitle: 'بازگشت',
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              CupertinoTextFormFieldRow(
                controller: _noteController,
                placeholder: 'متن یادداشت',
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'متن یادداشت الزامی است' : null,
                placeholderStyle: TextStyle(
                  color: _noteController.text.isEmpty
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.label,
                  fontSize: _noteController.text.isEmpty ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                mouseCursor: SystemMouseCursors.click,
                child: const Text('ذخیره'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final note = Note(
                      id: null,
                      forceId: widget.forceId,
                      note: _noteController.text,
                      noteDate: dateTimestamp(),
                    );
                    final appProvider =
                        Provider.of<AppProvider>(context, listen: false);
                    try {
                      appProvider.addNote(note.forceId, note.note, 1);
                      Navigator.pop(context);
                    } catch (e) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('خطا'),
                          content: Text(e.toString()),
                          actions: [
                            MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: CupertinoDialogAction(
                                  child: const Text('تأیید'),
                                  onPressed: () => Navigator.pop(context),
                                )),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class WeekdayPicker extends StatefulWidget {
  final int initialBitmask;
  final Function(int) onChange;

  const WeekdayPicker({
    super.key,
    required this.initialBitmask,
    required this.onChange,
  });

  @override
  _WeekdayPickerState createState() => _WeekdayPickerState();
}

class _WeekdayPickerState extends State<WeekdayPicker> {
  late List<bool> _selection;

  @override
  void initState() {
    super.initState();
    _selection = List.generate(
        7, (index) => (widget.initialBitmask & (1 << index)) != 0);
  }

  int _calculateBitmask() {
    int bitmask = 0;
    for (int i = 0; i < _selection.length; i++) {
      if (_selection[i]) bitmask |= (1 << i);
    }
    return bitmask;
  }

  @override
  Widget build(BuildContext context) {
    final days = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Row(
      children: [
        SizedBox(
          width: 8,
        ),
        Text("روز های کاری:"),
        SizedBox(
          width: 16,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppThemeProvider.toolbarColor,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selection[index] = !_selection[index];
                      widget.onChange(_calculateBitmask());
                    });
                  },
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selection[index]
                          ? CupertinoTheme.of(context).primaryColor
                          : CupertinoColors.inactiveGray.withOpacity(0.25),
                      boxShadow: _selection[index]
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4.0)
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: _selection[index]
                              ? Colors.white
                              : AppThemeProvider.backgroundColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
