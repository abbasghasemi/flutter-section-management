import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/providers/force_provider.dart';
import 'package:section_management/utility.dart';

import 'home_screen.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final _inUnitIds = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentDate = dateTimestamp();
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ValueListenableBuilder(
            valueListenable: _inUnitIds,
            builder: (context, value, child) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        CupertinoCheckbox(
                          mouseCursor: SystemMouseCursors.click,
                          value: value,
                          onChanged: (_) =>
                              _inUnitIds.value = !_inUnitIds.value,
                        ),
                        Text('گزارش نیروی های واحد'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: appProvider.getForcesStatus(
                          currentDate, [1, 2], value),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CupertinoPageScaffold(
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }
                        final unitStatus = snapshot.data ?? {};
                        final unitForces =
                            unitStatus['unitForces'] as List<Force>;
                        final presentForces =
                            unitStatus['presentForces'] as List<Force>;
                        final leaveForces =
                            unitStatus['leaveForces'] as List<Force>;
                        final oldLeaves =
                            unitStatus['oldLeaves'] as List<Leave>;
                        final sickForces =
                            unitStatus['sickForces'] as List<Force>;
                        final absentForces =
                            unitStatus['absentForces'] as List<Force>;
                        final detainedForces =
                            unitStatus['detainedForces'] as List<Force>;
                        final leaves = unitStatus['leaves'] as List<Leave>;
                        final missionForces =
                            unitStatus['missionForces'] as List<Force>;
                        return ListenableBuilder(
                            listenable: context.read<AppThemeProvider>(),
                            builder: (context, child) {
                              return ListView(
                                children: [
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: const Text('آمار کلی'),
                                    children: [
                                      CupertinoListTile(
                                          backgroundColorActivated:
                                              AppThemeProvider
                                                  .backgroundColorActivated,
                                          title: Text(
                                              'تعداد نیروها: ${unitStatus['totalForces']}')),
                                      CupertinoListTile(
                                          backgroundColorActivated:
                                              AppThemeProvider
                                                  .backgroundColorActivated,
                                          title: Text(
                                              'تعداد نیروهای ${value ? '' : 'غیر '}واحد: ${unitForces.length}')),
                                      CupertinoListTile(
                                          backgroundColorActivated:
                                              AppThemeProvider
                                                  .backgroundColorActivated,
                                          title: Text(
                                              'تعداد حاضرین ${value ? '' : 'غیر '}واحد: ${presentForces.length}')),
                                    ],
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای بازگشته اخیر (${oldLeaves.length})'),
                                    children: oldLeaves.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    'موردی برای نمایش وجود ندارد'))
                                          ]
                                        : oldLeaves.map((leave) {
                                            final s = unitForces.firstWhere(
                                                (s) => s.id == leave.forceId);
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای در مرخصی (${leaveForces.length})'),
                                    children: leaveForces.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title:
                                                    Text('نیروی در مرخصی نیست'))
                                          ]
                                        : leaveForces.map((s) {
                                            final leave = leaves.firstWhere(
                                              (l) =>
                                                  l.forceId == s.id &&
                                                  l.leaveType ==
                                                      LeaveType.presence,
                                            );
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای استعلاجی (${sickForces.length})'),
                                    children: sickForces.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    'نیروی در استعلاجی نیست'))
                                          ]
                                        : sickForces.map((s) {
                                            final leave = leaves.firstWhere(
                                              (l) =>
                                                  l.forceId == s.id &&
                                                  l.leaveType == LeaveType.sick,
                                            );
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای غایب (${absentForces.length})'),
                                    children: absentForces.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text('نیروی غایب نیست'))
                                          ]
                                        : absentForces.map((s) {
                                            final leave = leaves.firstWhere(
                                              (l) =>
                                                  l.forceId == s.id &&
                                                  l.leaveType ==
                                                      LeaveType.absent,
                                            );
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای بازداشتی (${detainedForces.length})'),
                                    children: detainedForces.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title:
                                                    Text('نیروی بازداشت نیست'))
                                          ]
                                        : detainedForces.map((s) {
                                            final leave = leaves.firstWhere(
                                              (l) =>
                                                  l.forceId == s.id &&
                                                  l.leaveType ==
                                                      LeaveType.detention,
                                            );
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                  CupertinoListSection(
                                    decoration: BoxDecoration(
                                        color: AppThemeProvider
                                            .backgroundColorDeActivated),
                                    backgroundColor:
                                        AppThemeProvider.backgroundColor,
                                    header: Text(
                                        'نیروهای در ماموریت (${missionForces.length})'),
                                    children: missionForces.isEmpty
                                        ? [
                                            CupertinoListTile(
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    'نیروی در ماموریت نیست'))
                                          ]
                                        : missionForces.map((s) {
                                            final leave = leaves.firstWhere(
                                              (l) =>
                                                  l.forceId == s.id &&
                                                  l.leaveType ==
                                                      LeaveType.detention,
                                            );
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CupertinoListTile(
                                                onTap: () {
                                                  HomeScreen.goToForceScreen();
                                                  context
                                                      .read<ForceProvider>()
                                                      .force = s;
                                                },
                                                backgroundColorActivated:
                                                    AppThemeProvider
                                                        .backgroundColorActivated,
                                                title: Text(
                                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                                subtitle: Text(
                                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
