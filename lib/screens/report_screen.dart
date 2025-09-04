import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/force.dart';
import 'package:section_management/models/leave.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/theme.dart';
import 'package:section_management/utility.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentDate = dateTimestamp();
    return FutureBuilder<Map<String, dynamic>>(
      future: appProvider.getForcesStatus(currentDate, [1, 2]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('گزارش')),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final unitStatus = snapshot.data ?? {};
        final unitForces = unitStatus['unitForces'] as List<Force>? ?? [];
        final presentForces = unitStatus['presentForces'] as List<Force>? ?? [];
        final leaveForces = unitStatus['leaveForces'] as List<Force>? ?? [];
        final sickForces = unitStatus['sickForces'] as List<Force>? ?? [];
        final absentForces = unitStatus['absentForces'] as List<Force>? ?? [];
        final detainedForces =
            unitStatus['detainedForces'] as List<Force>? ?? [];
        final leaves = unitStatus['leaves'] as List<Leave>? ?? [];
        return FutureBuilder<int>(
          future: appProvider.getTotalPresentForces(currentDate),
          builder: (context, totalPresentSnapshot) {
            return CupertinoPageScaffold(
              child: SafeArea(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, right: 16),
                      child: Text('گزارش'),
                    ),
                    CupertinoListSection(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
                      backgroundColor: DarkTheme.backgroundColor,
                      header: const Text('آمار کلی'),
                      children: [
                        CupertinoListTile(
                            backgroundColorActivated:
                                DarkTheme.backgroundColorActivated,
                            title: Text(
                                'تعداد نیروها: ${unitStatus['totalForces']}')),
                        CupertinoListTile(
                            backgroundColorActivated:
                                DarkTheme.backgroundColorActivated,
                            title: Text(
                                'تعداد نیروهای واحد: ${unitForces.length}')),
                        CupertinoListTile(
                            backgroundColorActivated:
                                DarkTheme.backgroundColorActivated,
                            title: Text(
                                'تعداد حاضرین واحد: ${presentForces.length}')),
                      ],
                    ),
                    CupertinoListSection(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
                      backgroundColor: DarkTheme.backgroundColor,
                      header: Text('نیروهای در مرخصی (${leaveForces.length})'),
                      children: leaveForces.isEmpty
                          ? [
                              CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text('نیروی در مرخصی نیست'))
                            ]
                          : leaveForces.map((s) {
                              final leave = leaves.firstWhere(
                                (l) =>
                                    l.forceId == s.id &&
                                    l.leaveType == LeaveType.presence,
                              );
                              return CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                subtitle: Text(
                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                ),
                              );
                            }).toList(),
                    ),
                    CupertinoListSection(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
                      backgroundColor: DarkTheme.backgroundColor,
                      header: Text('نیروهای استعلاجی (${sickForces.length})'),
                      children: sickForces.isEmpty
                          ? [
                              CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text('نیروی در استعلاجی نیست'))
                            ]
                          : sickForces.map((s) {
                              final leave = leaves.firstWhere(
                                (l) =>
                                    l.forceId == s.id &&
                                    l.leaveType == LeaveType.sick,
                                orElse: () => Leave(
                                  id: null,
                                  forceId: s.id!,
                                  fromDate: currentDate,
                                  toDate: null,
                                  leaveType: LeaveType.sick,
                                  details: [],
                                ),
                              );
                              return CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                subtitle: Text(
                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                ),
                              );
                            }).toList(),
                    ),
                    CupertinoListSection(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
                      backgroundColor: DarkTheme.backgroundColor,
                      header: Text('نیروهای غایب (${absentForces.length})'),
                      children: absentForces.isEmpty
                          ? [
                              CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text('نیروی غایب نیست'))
                            ]
                          : absentForces.map((s) {
                              final leave = leaves.firstWhere(
                                (l) =>
                                    l.forceId == s.id &&
                                    l.leaveType == LeaveType.absent,
                              );
                              return CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                subtitle: Text(
                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                ),
                              );
                            }).toList(),
                    ),
                    CupertinoListSection(
                      decoration: BoxDecoration(
                          color: DarkTheme.backgroundColorDeActivated),
                      backgroundColor: DarkTheme.backgroundColor,
                      header:
                          Text('نیروهای بازداشتی (${detainedForces.length})'),
                      children: detainedForces.isEmpty
                          ? [
                              CupertinoListTile(
                                  backgroundColorActivated:
                                      DarkTheme.backgroundColorActivated,
                                  title: Text('نیروی بازداشت نیست'))
                            ]
                          : detainedForces.map((s) {
                              final leave = leaves.firstWhere(
                                (l) =>
                                    l.forceId == s.id &&
                                    l.leaveType == LeaveType.detention,
                              );
                              return CupertinoListTile(
                                backgroundColorActivated:
                                    DarkTheme.backgroundColorActivated,
                                title: Text(
                                    '${s.firstName} ${s.lastName} (${s.fatherName})'),
                                subtitle: Text(
                                  'کد ملی: ${s.codeMeli} | از ${timestampToShamsi(leave.fromDate)} '
                                  'تا ${leave.toDate != null ? timestampToShamsi(leave.toDate!) : 'نامشخص'}',
                                ),
                              );
                            }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
