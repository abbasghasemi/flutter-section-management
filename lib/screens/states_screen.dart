import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/enums.dart';
import 'package:section_management/models/state.dart' as model;
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/utility.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final states = appProvider.states;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('مکان‌ها'),
        trailing: CupertinoButton(
          mouseCursor: SystemMouseCursors.click,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [const Icon(CupertinoIcons.add), Text("جدید")],
          ),
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const StateFormScreen()),
          ),
        ),
      ),
      child: SafeArea(
        child: states.isEmpty
            ? const Center(child: Text('مکانی یافت نشد'))
            : ListView.separated(
                separatorBuilder: (context, i) => Divider(
                  indent: 20,
                ),
                itemCount: states.length,
                itemBuilder: (context, index) {
                  final state = states[index];
                  final unit =
                      appProvider.units.firstWhere((u) => u.id == state.unitId);
                  return CupertinoListTile(
                    backgroundColorActivated:
                        AppThemeProvider.backgroundColorActivated,
                    title: Text('${state.name} (${state.stateType.fa})'),
                    subtitle: Text('${unit.name}'),
                    leadingSize: 20,
                    leading: GestureDetector(
                      onTap: () {
                        setState(() {
                          appProvider.updateState(model.State(
                            id: state.id,
                            name: state.name,
                            isActive: state.isActive,
                            isArmed: !state.isArmed,
                            stateType: state.stateType,
                            unitId: state.unitId,
                          ));
                        });
                      },
                      onSecondaryTap: () {
                        setState(() {
                          appProvider.updateState(model.State(
                            id: state.id,
                            name: state.name,
                            isActive: !state.isActive,
                            isArmed: state.isArmed,
                            stateType: state.stateType,
                            unitId: state.unitId,
                          ));
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: state.isActive
                                  ? Colors.green
                                  : Colors.orange),
                          child: state.isArmed
                              ? Icon(
                                  CupertinoIcons.arrow_2_circlepath,
                                  color: Colors.white,
                                  size: 17,
                                )
                              : null,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'ویرایش',
                          child: CupertinoButton(
                            mouseCursor: SystemMouseCursors.click,
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.pencil),
                            onPressed: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    StateFormScreen(state: state),
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'حذف',
                          child: CupertinoButton(
                            mouseCursor: SystemMouseCursors.click,
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.delete),
                            onPressed: () async {
                              if (!appProvider.canDeleteState(state.id!)) {
                                await showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('خطا'),
                                    content: const Text(
                                        'مکان قابل حذف نیست زیرا در لوح پستی استفاده شده است'),
                                    actions: [
                                      MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: CupertinoDialogAction(
                                            child: const Text('تأیید'),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          )),
                                    ],
                                  ),
                                );
                                return;
                              }
                              final confirmed = await showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('حذف مکان'),
                                  content: Text(
                                      'آیا از حذف مکان ${state.name} مطمئن هستید؟'),
                                  actions: [
                                    MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: CupertinoDialogAction(
                                          child: const Text('لغو'),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        )),
                                    MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('حذف'),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        )),
                                  ],
                                ),
                              );
                              if (confirmed) {
                                try {
                                  appProvider.deleteState(state.id!);
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
                                              onPressed: () =>
                                                  Navigator.pop(context),
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
                  );
                },
              ),
      ),
    );
  }
}

class StateFormScreen extends StatefulWidget {
  final model.State? state;

  const StateFormScreen({super.key, this.state});

  @override
  State<StateFormScreen> createState() => _StateFormScreenState();
}

class _StateFormScreenState extends State<StateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _isActive;
  late bool _isArmed;
  late StateType _stateType;
  late int _unitId;
  late AppRestartProvider _appRestart;

  void _restart() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
    _nameController = TextEditingController(text: widget.state?.name ?? '');
    _isActive = widget.state?.isActive ?? true;
    _isArmed = widget.state?.isArmed ?? false;
    _stateType = widget.state?.stateType ?? StateType.post;
    _unitId = widget.state?.unitId ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final units = appProvider.units.take(2);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.state == null ? 'افزودن مکان' : 'ویرایش مکان'),
        leading: CupertinoPageBack(
          previousPageTitle: 'مکان‌ها',
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 16,
              ),
              CupertinoTextFormFieldRow(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                controller: _nameController,
                autofocus: true,
                prefix: Text('نام مکان '),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'نام مکان الزامی است' : null,
              ),
              CupertinoListTile(
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: const Text('فعال'),
                trailing: CupertinoSwitch(
                  mouseCursor: SwitchWidgetStateProperty(),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              CupertinoListTile(
                backgroundColorActivated:
                    AppThemeProvider.backgroundColorActivated,
                title: const Text('مسلح'),
                trailing: CupertinoSwitch(
                  mouseCursor: SwitchWidgetStateProperty(),
                  value: _isArmed,
                  onChanged: (value) => setState(() => _isArmed = value),
                ),
              ),
              CupertinoListTile(
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
                            .take(3)
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
              CupertinoListTile(
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CupertinoButton.filled(
                  mouseCursor: SystemMouseCursors.click,
                  child: Text(widget.state == null ? 'افزودن' : 'ذخیره'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final state = model.State(
                        id: widget.state?.id,
                        name: _nameController.text,
                        isActive: _isActive,
                        isArmed: _isArmed,
                        stateType: _stateType,
                        unitId: _unitId,
                      );
                      final appProvider =
                          Provider.of<AppProvider>(context, listen: false);
                      try {
                        if (widget.state == null) {
                          appProvider.addState(state);
                        } else {
                          appProvider.updateState(state);
                        }
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _appRestart.removeListener(_restart);
    super.dispose();
  }
}
