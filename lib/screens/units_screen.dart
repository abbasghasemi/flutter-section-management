import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';
import 'package:section_management/utility.dart';

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final units = appProvider.units;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('واحدها'),
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
            CupertinoPageRoute(builder: (context) => const UnitFormScreen()),
          ),
        ),
      ),
      child: SafeArea(
        child: units.isEmpty
            ? const Center(child: Text('واحدی یافت نشد'))
            : ListView.separated(
                separatorBuilder: (context, i) => Divider(
                  indent: 20,
                ),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return CupertinoListTile(
                    title: Text(unit.name),
                    subtitle: Text(unit.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            "نیروی قابل استفاده: ${unit.maxUsage == -1 ? '♾️' : unit.maxUsage}"),
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
                                    UnitFormScreen(unit: unit),
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
                              if (!appProvider.canDeleteUnit(unit.id!)) {
                                await showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('خطا'),
                                    content: const Text(
                                        'واحد قابل حذف نیست زیرا به نیرو یا مکان متصل است'),
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
                                  title: const Text('حذف واحد'),
                                  content: Text(
                                      'آیا از حذف واحد ${unit.name} مطمئن هستید؟'),
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
                                  appProvider.deleteUnit(unit.id!);
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

class UnitFormScreen extends StatefulWidget {
  final Unit? unit;

  const UnitFormScreen({super.key, this.unit});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxUsageController;
  late TextEditingController _descriptionController;
  late AppRestartProvider _appRestart;
  late ValueNotifier<bool> _fullCapacity;

  void _restart() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _maxUsageController =
        TextEditingController(text: widget.unit?.maxUsage.toString() ?? '1');
    _fullCapacity = ValueNotifier(_maxUsageController.text == "-1");
    if (_fullCapacity.value) {
      _maxUsageController.text = "1";
    }
    _descriptionController =
        TextEditingController(text: widget.unit?.description ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.unit == null ? 'افزودن واحد' : 'ویرایش واحد'),
        leading: CupertinoPageBack(
          previousPageTitle: 'واحدها',
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                height: 16,
              ),
              CupertinoTextFormFieldRow(
                controller: _nameController,
                prefix: Text('نام واحد   '),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'نام واحد الزامی است' : null,
              ),
              CupertinoTextFormFieldRow(
                controller: _descriptionController,
                prefix: Text('توضیحات '),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder(
                  valueListenable: _fullCapacity,
                  builder: (context, alwaysOff, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: alwaysOff
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14.0, horizontal: 20),
                                  child: Text(
                                      'حداکثر تعداد نیروی قابل استفاده: تمامی ظرفیت'),
                                )
                              : CupertinoTextFormFieldRow(
                                  controller: _maxUsageController,
                                  prefix:
                                      Text('حداکثر تعداد نیروی قابل استفاده '),
                                  maxLines: 1,
                                  maxLength: 3,
                                  keyboardType: TextInputType.numberWithOptions(
                                      signed: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]'))
                                  ],
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CupertinoColors.systemGrey),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'حداکثر تعداد استفاده الزامی است';
                                    }
                                    return null;
                                  },
                                ),
                        ),
                        CupertinoSwitch(
                            mouseCursor: SwitchWidgetStateProperty(),
                            value: alwaysOff,
                            onChanged: (_) {
                              _fullCapacity.value = !alwaysOff;
                            }),
                        SizedBox(
                          width: 8,
                        ),
                      ],
                    );
                  }),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                mouseCursor: SystemMouseCursors.click,
                child: Text(widget.unit == null ? 'افزودن' : 'ذخیره'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    try {
                      if (widget.unit == null) {
                        appProvider.addUnit(
                            _nameController.text,
                            int.parse(_maxUsageController.text),
                            _descriptionController.text);
                      } else {
                        final unit = widget.unit!;
                        unit.name = _nameController.text;
                        unit.maxUsage = _fullCapacity.value
                            ? -1
                            : int.parse(_maxUsageController.text);
                        unit.description = _descriptionController.text;
                        appProvider.updateUnit(unit);
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
