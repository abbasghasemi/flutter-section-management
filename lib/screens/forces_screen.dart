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
import 'package:section_management/models/unit.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/theme.dart';
import 'package:section_management/utility.dart';

class ForcesScreen extends StatefulWidget {
  const ForcesScreen({super.key});

  @override
  State<ForcesScreen> createState() => _ForcesScreenState();
}

class _ForcesScreenState extends State<ForcesScreen> {
  int _offset = 0;
  final int _limit = 20;
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

  void _restart() {
    _offset = 0;
    _loadForces();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _loadForces();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
  }

  Future<void> _loadForces() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (_presentFilter.value) {
      _filteredForces = await Provider.of<AppProvider>(context, listen: false)
          .getPresentForces(
        update: true,
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
    if (_isLoading || _presentFilter.value) return;
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
        backgroundColor: DarkTheme.backgroundColor,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
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
                    builder: (context) => const ForceFormScreen()),
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
                    ? Border(left: BorderSide(color: DarkTheme.toolbarColor))
                    : null,
                color: DarkTheme.backgroundColor,
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 110),
                child: _sidebarFilterOpened
                    ? Container(
                        width: 200,
                        color: DarkTheme.backgroundColor,
                        child: Column(
                          children: [
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _selectedUnitId,
                              builder: (context, unitId, _) =>
                                  CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                  unitId == null
                                      ? 'واحد: همه'
                                      : 'واحد: ${units.firstWhere((u) => u.id == unitId, orElse: () => Unit(id: 0, name: 'نامشخص')).name}',
                                  style: theme.textTheme.actionSmallTextStyle
                                      .apply(color: Colors.white),
                                ),
                                onTap: () async {
                                  final newUnitId =
                                      await showCupertinoModalPopup<int>(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      title: Text('انتخاب واحد'),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: Text('همه'),
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                        ),
                                        ...units.map((unit) =>
                                            CupertinoActionSheetAction(
                                              child: Text(unit.name),
                                              onPressed: () => Navigator.pop(
                                                  context, unit.id),
                                            )),
                                      ],
                                      cancelButton: CupertinoActionSheetAction(
                                        child: Text('لغو'),
                                        onPressed: () => Navigator.pop(context),
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
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _canArmedFilter,
                              builder: (context, canArmed, _) =>
                                  CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                  'مسلح: ${canArmed == null ? 'همه' : canArmed ? 'بله' : 'خیر'}',
                                  style: theme.textTheme.actionSmallTextStyle
                                      .apply(color: Colors.white),
                                ),
                                onTap: () async {
                                  final newCanArmed =
                                      await showCupertinoModalPopup<bool>(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      title: Text('انتخاب وضعیت مسلح'),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: Text('همه'),
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                        ),
                                        CupertinoActionSheetAction(
                                          child: Text('بله'),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                        CupertinoActionSheetAction(
                                          child: Text('خیر'),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        ),
                                      ],
                                      cancelButton: CupertinoActionSheetAction(
                                        child: Text('لغو'),
                                        onPressed: () => Navigator.pop(context),
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
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _endDateFilter,
                              builder: (context, endDate, _) =>
                                  CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                  'پایان خدمت: ${endDate == null ? '-' : timestampToShamsi(endDate)}',
                                  style: theme.textTheme.actionSmallTextStyle
                                      .apply(color: Colors.white),
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
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _leaveTypeFilter,
                              builder: (context, leaveType, _) =>
                                  CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                  'نوع مرخصی: ${leaveType == null ? 'همه' : leaveType.fa}',
                                  style: theme.textTheme.actionSmallTextStyle
                                      .apply(color: Colors.white),
                                ),
                                onTap: () async {
                                  final newLeaveType =
                                      await showCupertinoModalPopup<LeaveType>(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      title: Text('انتخاب نوع مرخصی'),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: Text('همه'),
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                        ),
                                        ...LeaveType.values.map((type) =>
                                            CupertinoActionSheetAction(
                                              child: Text(type.fa),
                                              onPressed: () =>
                                                  Navigator.pop(context, type),
                                            )),
                                      ],
                                      cancelButton: CupertinoActionSheetAction(
                                        child: Text('لغو'),
                                        onPressed: () => Navigator.pop(context),
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
                            ValueListenableBuilder(
                              valueListenable: _leaveTypeFilter,
                              builder: (context, leaveType, _) =>
                                  ValueListenableBuilder(
                                valueListenable: _leaveDateFilter,
                                builder: (context, leaveDate, _) =>
                                    CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text(
                                    leaveDate != null
                                        ? timestampToShamsi(leaveDate)
                                        : 'تاریخ مرخصی: -',
                                    style: theme.textTheme.actionSmallTextStyle
                                        .apply(
                                            color: leaveType == null
                                                ? Colors.grey
                                                : Colors.white),
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
                            const Divider(),
                            ValueListenableBuilder(
                              valueListenable: _presentFilter,
                              builder: (context, present, _) =>
                                  CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'حاضرین',
                                      style: theme
                                          .textTheme.actionSmallTextStyle
                                          .apply(color: Colors.white),
                                    ),
                                    SizedBox(
                                      width: 20,
                                      child: Transform.scale(
                                        scale: .7,
                                        child: CupertinoSwitch(
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
                    padding:
                        const EdgeInsets.only(left: 8.0, right: 8, bottom: 10),
                    child: CupertinoSearchTextField(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
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
                                  itemCount: _filteredForces.length +
                                      (_isLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _filteredForces.length) {
                                      return Center(
                                          child: CupertinoActivityIndicator());
                                    }
                                    final force = _filteredForces[index];
                                    return CupertinoListTile(
                                      leadingToTitle: 5,
                                      backgroundColorActivated:
                                          DarkTheme.backgroundColorActivated,
                                      padding: EdgeInsets.zero,
                                      leading: Text('${index + 1}'),
                                      title: Text(
                                          '${force.firstName} ${force.lastName} (${force.fatherName})'),
                                      subtitle: Text(
                                          'کد ملی: ${force.codeMeli} - پایان خدمت: ${timestampToShamsi(force.endDate)} - ${force.unitName}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FutureBuilder(
                                            future: appProvider
                                                .getPostsCountByForceId(
                                                    force.id!),
                                            builder: (context, snap) {
                                              if (!snap.hasData) {
                                                return CupertinoActivityIndicator();
                                              }
                                              return Text("${snap.data} پست");
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: const Icon(
                                                CupertinoIcons.forward),
                                          ),
                                        ],
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              ForceDetailScreen(force: force),
                                        ),
                                      ),
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
    super.dispose();
  }
}

class ForceDetailScreen extends StatelessWidget {
  final Force force;

  const ForceDetailScreen({super.key, required this.force});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final daysOffText = force.daysOff == 0 ? 'همیشه' : force.daysOff.toString();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${force.firstName} ${force.lastName}'),
        previousPageTitle: 'نیروها',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'ویرایش نیرو',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.pencil),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ForceFormScreen(force: force),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'افزودن یادداشت',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.doc_text),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AddNoteScreen(forceId: force.id!),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'ثبت مرخصی',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.calendar_badge_minus),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) =>
                        ForceLeaveFormScreen(forceId: force.id!),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'حذف نیرو',
              child: CupertinoButton(
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
                        CupertinoDialogAction(
                          child: const Text('لغو'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('حذف'),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );
                  if (confirmed) {
                    appProvider.deleteForce(force.id!);
                    Navigator.pop(context);
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
                  color: DarkTheme.backgroundColorDeActivated),
              backgroundColor: DarkTheme.backgroundColor,
              header: const Text('اطلاعات نیرو'),
              children: [
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('کد ملی: ${force.codeMeli}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('نام: ${force.firstName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('نام خانوادگی: ${force.lastName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('نام پدر: ${force.fatherName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('بومی: ${force.isNative ? 'بله' : 'خیر'}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('مسلح: ${force.canArmed ? 'بله' : 'خیر'}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('واحد: ${force.unitName}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('مسئولیت: ${force.stateType.fa}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('روزهای استراحت: $daysOffText')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text('شماره تلفن: ${force.phoneNo}')),
                CupertinoListTile(
                    backgroundColorActivated:
                        DarkTheme.backgroundColorActivated,
                    title: Text(
                        'پایان خدمت: ${timestampToShamsi(force.endDate)}')),
              ],
            ),
            FutureBuilder(
              future: appProvider.getLeavesByForceId(force.id!),
              builder: (context, data) {
                if (data.hasData) {
                  final leaves = data.data!;
                  return CupertinoListSection(
                    decoration: BoxDecoration(
                        color: DarkTheme.backgroundColorDeActivated),
                    backgroundColor: DarkTheme.backgroundColor,
                    header: const Text('مرخصی‌ها/غیبت‌ها'),
                    children: leaves.isEmpty
                        ? [
                            CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text('موری موجود نیست'))
                          ]
                        : leaves.map((leave) {
                            final List<LeaveDetail> details = leave.details;
                            final detailsText = details.isNotEmpty
                                ? details
                                    .map((d) => '${d.fa}: ${d.days} روز')
                                    .join(', ')
                                : 'بدون جزئیات';
                            return CupertinoListTile(
                              backgroundColorActivated:
                                  DarkTheme.backgroundColorActivated,
                              title: Text('${leave.leaveType.fa}'),
                              subtitle: Text(
                                'از ${timestampToShamsi(leave.fromDate)} '
                                'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'} - $detailsText',
                              ),
                              trailing: const Icon(CupertinoIcons.pencil),
                              onTap: () => Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ForceLeaveFormScreen(
                                      forceId: force.id!, leave: leave),
                                ),
                              ),
                            );
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
                        color: DarkTheme.backgroundColorDeActivated),
                    backgroundColor: DarkTheme.backgroundColor,
                    header: const Text('یادداشت‌ها'),
                    children: notes.isEmpty
                        ? [
                            CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text('یادداشتی موجود نیست'))
                          ]
                        : notes
                            .map((note) => CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text(
                                    note.note.replaceAll("\n", ' '),
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .actionSmallTextStyle
                                        .apply(color: Colors.white),
                                  ),
                                  subtitle:
                                      Text(timestampToShamsi(note.noteDate)),
                                ))
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
                        color: DarkTheme.backgroundColorDeActivated),
                    backgroundColor: DarkTheme.backgroundColor,
                    header: Text('پست‌ها (${posts.length})'),
                    children: [
                      Column(
                        children: posts.isEmpty
                            ? [
                                CupertinoListTile(
                                    backgroundColorActivated:
                                        DarkTheme.backgroundColorActivated,
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
                                      DarkTheme.backgroundColorActivated,
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

  const ForceLeaveFormScreen({super.key, this.leave, required this.forceId});

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
        [LeaveDetail(title: _getDetailsType().first, days: 0)]);
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
        middle: Text(widget.leave == null ? 'ثبت مرخصی' : 'ویرایش مرخصی'),
        previousPageTitle: 'بازگشت',
        trailing: widget.leave != null
            ? Tooltip(
                message: 'حذف',
                child: CupertinoButton(
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
                          CupertinoDialogAction(
                            child: Text('لغو'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: Text('حذف',
                                style: TextStyle(
                                    color: CupertinoColors.destructiveRed)),
                            onPressed: () => Navigator.pop(context, true),
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
                      );
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
                    child: Text('انتخاب مرخصی'),
                    onPressed: () async {
                      final newLeaveType =
                          await showCupertinoModalPopup<LeaveType>(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: Text('انتخاب مرخصی'),
                          actions: LeaveType.values
                              .map((type) => CupertinoActionSheetAction(
                                    child: Text(type.fa),
                                    onPressed: () =>
                                        Navigator.pop(context, type),
                                  ))
                              .toList(),
                          cancelButton: CupertinoActionSheetAction(
                            child: Text('لغو'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      );
                      if (newLeaveType != null && newLeaveType != leaveType) {
                        _leaveType.value = newLeaveType;
                        _details.value = [
                          LeaveDetail(title: (_getDetailsType().first), days: 0)
                        ];
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
                        _toDate.value = null;
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
                    child: Text('انتخاب تاریخ'),
                    onPressed: () async {
                      final date = await showPersianDatePicker(
                        context: context,
                        initialDate: Jalali.fromMillisecondsSinceEpoch(
                            _fromDate.value * 1000),
                        firstDate: Jalali.fromMillisecondsSinceEpoch(
                            _fromDate.value * 1000),
                        lastDate: Jalali.fromMillisecondsSinceEpoch(
                                _fromDate.value * 1000)
                            .add(years: 1),
                      );
                      _toDate.value = date == null
                          ? null
                          : date.millisecondsSinceEpoch ~/ 1000;
                    },
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
                            minimumSize: Size(24, 24),
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(CupertinoIcons.minus_circle,
                                color: CupertinoColors.destructiveRed),
                            onPressed: () => _details.value = List.from(details)
                              ..removeAt(index),
                          ),
                        SizedBox(
                          width: 130,
                          child: CupertinoTextFormFieldRow(
                            maxLength: 2,
                            maxLines: 1,
                            initialValue: detail.days.toString(),
                            prefix: Text('تعداد روز  '),
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
                            validator: (value) =>
                                value!.isEmpty ? 'تعداد روز الزامی است' : null,
                          ),
                        ),
                        Expanded(
                          child: CupertinoListTile(
                            title: Text('عنوان: ${detail.fa}'),
                            trailing: !_checkAllowAddBtn(details.length)
                                ? null
                                : CupertinoButton(
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
                                                    child:
                                                        Text((t as FaName).fa),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, t),
                                                  ))
                                              .toList(),
                                          cancelButton:
                                              CupertinoActionSheetAction(
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
                  child: Text(widget.leave == null ? 'ثبت' : 'ذخیره'),
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _details.value.every((d) => d.days > 0) &&
                        (_toDate.value != null ||
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
                              widget.forceId,
                              'تغییرات مرخصی: $changes',
                            );
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
                              CupertinoDialogAction(
                                child: Text('تأیید'),
                                onPressed: () => Navigator.pop(context),
                              ),
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
                            CupertinoDialogAction(
                              child: Text('تأیید'),
                              onPressed: () => Navigator.pop(context),
                            ),
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

  bool _checkAllowAddBtn(int length) {
    if (_leaveType.value == LeaveType.presence && length >= 4) {
      return false;
    }
    if (_leaveType.value == LeaveType.sick && length >= 2) {
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

  const ForceFormScreen({super.key, this.force});

  @override
  State<ForceFormScreen> createState() => _ForceFormScreenState();
}

class _ForceFormScreenState extends State<ForceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeMeliController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _phoneNoController;
  late bool _isNative;
  late int _endDate;
  late bool _canArmed;
  late int _unitId;
  late int _daysOff;
  late StateType _stateType;

  @override
  void initState() {
    super.initState();
    _codeMeliController =
        TextEditingController(text: widget.force?.codeMeli ?? '');
    _firstNameController =
        TextEditingController(text: widget.force?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.force?.lastName ?? '');
    _fatherNameController =
        TextEditingController(text: widget.force?.fatherName ?? '');
    _phoneNoController =
        TextEditingController(text: widget.force?.phoneNo.toString() ?? '');
    _isNative = widget.force?.isNative ?? false;
    _endDate = widget.force?.endDate ?? dateTimestamp();
    _canArmed = widget.force?.canArmed ?? false;
    _unitId = widget.force?.unitId ?? 1;
    _daysOff = widget.force?.daysOff ?? 1;
    _stateType = widget.force?.stateType ?? StateType.post;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final units = appProvider.units;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: widget.force == null ? 'نیروها' : 'بازگشت',
        middle: Text(widget.force == null ? 'افزودن نیرو' : 'ویرایش نیرو'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              CupertinoTextFormFieldRow(
                controller: _codeMeliController,
                prefix: Text('کد ملی              '),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'کد ملی الزامی است' : null,
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
                prefix: Text('روزهای استراحت '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                initialValue: _daysOff.toString(),
                maxLength: 2,
                onChanged: (value) =>
                    setState(() => _daysOff = int.tryParse(value) ?? 0),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'روزهای استراحت الزامی است';
                  } else if (value >= '0' && value <= '30') {
                    return null;
                  }
                  return 'عددی بین 0 تا 30 وارد کنید';
                },
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated: DarkTheme.backgroundColorActivated,
                title: Text('بومی: ${_isNative ? 'بله' : 'خیر'}'),
                trailing: CupertinoSwitch(
                  value: _isNative,
                  onChanged: (value) => setState(() => _isNative = value),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated: DarkTheme.backgroundColorActivated,
                title: Text('مسلح: ${_canArmed ? 'بله' : 'خیر'}'),
                trailing: CupertinoSwitch(
                  value: _canArmed,
                  onChanged: (value) => setState(() => _canArmed = value),
                ),
              ),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColorActivated: DarkTheme.backgroundColorActivated,
                title: Text('پایان خدمت: ${timestampToShamsi(_endDate)}'),
                trailing: CupertinoButton(
                  child: const Text('انتخاب تاریخ'),
                  onPressed: () async {
                    final date = await showPersianDatePicker(
                      context: context,
                      initialDate: Jalali.now(),
                      firstDate: Jalali.now().add(years: -1),
                      lastDate: Jalali.now().add(years: 1),
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
                backgroundColorActivated: DarkTheme.backgroundColorActivated,
                title: Text(
                    'واحد: ${units.firstWhere((u) => u.id == _unitId, orElse: () => Unit(id: 0, name: 'نامشخص')).name}'),
                trailing: CupertinoButton(
                  child: const Text('انتخاب واحد'),
                  onPressed: () async {
                    final unitId = await showCupertinoModalPopup<int>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text('انتخاب واحد'),
                        actions: units
                            .map((unit) => CupertinoActionSheetAction(
                                  child: Text(unit.name),
                                  onPressed: () =>
                                      Navigator.pop(context, unit.id),
                                ))
                            .toList(),
                        cancelButton: CupertinoActionSheetAction(
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
                backgroundColorActivated: DarkTheme.backgroundColorActivated,
                title: Text('مسئولیت: ${_stateType.fa}'),
                trailing: CupertinoButton(
                  child: const Text('انتخاب مسئولیت'),
                  onPressed: () async {
                    final stateType = await showCupertinoModalPopup<StateType>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text('انتخاب مسئولیت'),
                        actions: StateType.values
                            .map((type) => CupertinoActionSheetAction(
                                  child: Text(type.fa),
                                  onPressed: () => Navigator.pop(context, type),
                                ))
                            .toList(),
                        cancelButton: CupertinoActionSheetAction(
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
                  child: Text(widget.force == null ? 'افزودن' : 'ذخیره'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final force = Force(
                        id: widget.force?.id,
                        codeMeli: _codeMeliController.text,
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        fatherName: _fatherNameController.text,
                        isNative: _isNative,
                        endDate: _endDate,
                        createdDate:
                            widget.force?.createdDate ?? dateTimestamp(),
                        canArmed: _canArmed,
                        unitId: _unitId,
                        daysOff: _daysOff,
                        unitName: widget.force?.unitName ??
                            units.firstWhere((i) => i.id == _unitId).name,
                        phoneNo: int.tryParse(_phoneNoController.text) ?? 0,
                        stateType: _stateType,
                      );
                      final appProvider =
                          Provider.of<AppProvider>(context, listen: false);
                      try {
                        if (widget.force == null) {
                          appProvider.addForce(force);
                        } else {
                          appProvider.updateForce(widget.force!, force);
                        }
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      } catch (e) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('نیروی تکراری'),
                            content: Text('کد ملی وارد شده، قبلا ثبت شده است'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('تأیید'),
                                onPressed: () => Navigator.pop(context),
                              ),
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

  const AddNoteScreen({super.key, required this.forceId});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('افزودن یادداشت'),
        previousPageTitle: 'بازگشت',
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
                      appProvider.addNote(note.forceId, note.note);
                      Navigator.pop(context);
                    } catch (e) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('خطا'),
                          content: Text(e.toString()),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('تأیید'),
                              onPressed: () => Navigator.pop(context),
                            ),
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
