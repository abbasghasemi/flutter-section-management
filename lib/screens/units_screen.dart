import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:section_management/models/unit.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_restart.dart';

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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'ویرایش',
                          child: CupertinoButton(
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
                                      CupertinoDialogAction(
                                        child: const Text('تأیید'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
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
                                    CupertinoDialogAction(
                                      child: const Text('لغو'),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('حذف'),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
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
                                        CupertinoDialogAction(
                                          child: const Text('تأیید'),
                                          onPressed: () =>
                                              Navigator.pop(context),
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
  late AppRestartProvider _appRestart;

  void _restart() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _appRestart = context.read<AppRestartProvider>();
    _appRestart.addListener(_restart);
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.unit == null ? 'افزودن واحد' : 'ویرایش واحد'),
        previousPageTitle: 'واحدها',
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
                placeholder: 'نام واحد',
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(3),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'نام واحد الزامی است' : null,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                child: Text(widget.unit == null ? 'افزودن' : 'ذخیره'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    try {
                      if (widget.unit == null) {
                        appProvider.addUnit(_nameController.text);
                      } else {
                        appProvider.updateUnit(
                            widget.unit!.id!, _nameController.text);
                      }
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
