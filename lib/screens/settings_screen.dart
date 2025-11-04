import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/utility.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formMultiplier = GlobalKey<FormState>();
  final GlobalKey<FormState> _formDriver = GlobalKey<FormState>();
  final GlobalKey<FormState> _formPasswd = GlobalKey<FormState>();
  final GlobalKey<FormState> _formPostCount = GlobalKey<FormState>();
  final GlobalKey<FormState> _formSeniorPostCount = GlobalKey<FormState>();
  final GlobalKey<FormState> _formFontSizeName = GlobalKey<FormState>();
  final GlobalKey<FormState> _formFontSizeTitle = GlobalKey<FormState>();

  Future<void> _savePassword(String newPassword) async {
    _passwordController.clear();
    _oldPasswordController.clear();
    context.read<AppProvider>().setPassword(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListenableBuilder(
            listenable: context.read<AppThemeProvider>(),
            builder: (context, child) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                      'تنظیمات - دفعات بارگزاری دیتابیس ${provider.totalImportDatabase()}'),
                  Form(
                    key: _formPasswd,
                    child: CupertinoListSection(
                      backgroundColor: AppThemeProvider.backgroundColor,
                      separatorColor: Colors.transparent,
                      decoration: BoxDecoration(
                          color: AppThemeProvider.backgroundColorDeActivated,
                          borderRadius: BorderRadius.circular(3)),
                      header: const Text('رمز عبور'),
                      children: [
                        CupertinoTextFormFieldRow(
                          controller: _oldPasswordController,
                          placeholder: 'رمز عبور قدیم',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز عبور  قدیم نمی‌تواند خالی باشد';
                            }
                            if (_oldPasswordController.text !=
                                provider.getPassword()) {
                              return 'رمز عبور قدیم اشتباه است';
                            }
                            return null;
                          },
                        ),
                        Divider(
                          indent: 24,
                          endIndent: 24,
                        ),
                        CupertinoTextFormFieldRow(
                          controller: _passwordController,
                          placeholder: 'رمز عبور جدید',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز عبور جدید نمی‌تواند خالی باشد';
                            }
                            return null;
                          },
                        ),
                        Divider(
                          indent: 24,
                          endIndent: 24,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0, right: 24),
                            child: CupertinoButton.filled(
                              mouseCursor: SystemMouseCursors.click,
                              child: const Text('تغییر رمز عبور'),
                              onPressed: () async {
                                if (_formPasswd.currentState!.validate()) {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('تأیید تغییر رمز'),
                                      content: Text(
                                          'آیا از تغییر رمز عبور به ${_passwordController.text} مطمئن هستید؟'),
                                      actions: [
                                        MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: CupertinoDialogAction(
                                              child: const Text('لغو'),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            )),
                                        MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: CupertinoDialogAction(
                                              child: const Text('تأیید'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _savePassword(
                                                    _passwordController.text);
                                              },
                                            )),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoListSection(
                    backgroundColor: AppThemeProvider.backgroundColor,
                    separatorColor: Colors.transparent,
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated,
                        borderRadius: BorderRadius.circular(3)),
                    header: const Text('لوح پستی'),
                    children: [
                      Form(
                        key: _formPostCount,
                        child: CupertinoTextFormFieldRow(
                          initialValue: provider.postCount().toString(),
                          prefix: Text("تعداد پاس ها:"),
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (_formPostCount.currentState!.validate()) {
                              final num = int.parse(value);
                              provider.setPostCount(num);
                            }
                          },
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value > '2' && value < '7') {
                              return null;
                            }
                            return 'تعداد پاس ها باید بین 3 تا 6 باشد';
                          },
                        ),
                      ),
                      Divider(),
                      Form(
                        key: _formSeniorPostCount,
                        child: CupertinoTextFormFieldRow(
                          initialValue: provider.seniorPostCount().toString(),
                          prefix: Text("تعداد پاسبخش ها:"),
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (_formSeniorPostCount.currentState!.validate()) {
                              final num = int.parse(value);
                              provider.setSeniorPostCount(num);
                            }
                          },
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value > '1' && value < '5') {
                              return null;
                            }
                            return 'تعداد پاسبخش ها باید بین 2 تا 4 باشد';
                          },
                        ),
                      ),
                      Divider(),
                      Form(
                        key: _formDriver,
                        child: CupertinoTextFormFieldRow(
                          initialValue: provider.driverCount.toString(),
                          prefix: Text("تعداد رانندگان:"),
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (_formDriver.currentState!.validate()) {
                              final num = int.parse(value);
                              provider.setDriverCount(num);
                            }
                          },
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value > '0' && value < '5') {
                              return null;
                            }
                            return 'تعداد رانندگان باید بین 1 تا 4 باشد';
                          },
                        ),
                      ),
                      Divider(),
                      Form(
                        key: _formFontSizeName,
                        child: CupertinoTextFormFieldRow(
                          initialValue: provider.fontSizeName().toString(),
                          prefix: Text("اندازه فونت اسامی:"),
                          maxLength: 2,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (_formFontSizeName.currentState!.validate()) {
                              final num = int.parse(value);
                              provider.setFontSizeName(num);
                            }
                          },
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                int.parse(value) > 6 &&
                                int.parse(value) < 22) {
                              return null;
                            }
                            return 'اندازه فونت باید بین 7 تا 21 باشد';
                          },
                        ),
                      ),
                      Divider(),
                      Form(
                        key: _formFontSizeTitle,
                        child: CupertinoTextFormFieldRow(
                          initialValue: provider.fontSizeTitle().toString(),
                          prefix: Text("اندازه فونت عناوین:"),
                          maxLength: 2,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (_formFontSizeTitle.currentState!.validate()) {
                              final num = int.parse(value);
                              provider.setFontSizeTitle(num);
                            }
                          },
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                int.parse(value) > 6 &&
                                int.parse(value) < 22) {
                              return null;
                            }
                            return 'اندازه فونت باید بین 7 تا 21 باشد';
                          },
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("محدودیت حداکثر استفاده ی نیروی واحد ها"),
                            CupertinoSwitch(
                                mouseCursor: SwitchWidgetStateProperty(),
                                value: provider.allowFilterMaxUsage(),
                                onChanged: (value) {
                                  provider.setAllowFilterMaxUsage(value);
                                  setState(() {});
                                }),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("اولویت انتخاب با نیروهای واحد"),
                            CupertinoSwitch(
                                mouseCursor: SwitchWidgetStateProperty(),
                                value: provider.allowFilterUnitPriority(),
                                onChanged: (value) {
                                  provider.setAllowFilterUnitPriority(value);
                                  setState(() {});
                                }),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("نمایش نام پدر در لوح پستی"),
                            CupertinoSwitch(
                                mouseCursor: SwitchWidgetStateProperty(),
                                value: provider.showFatherName(),
                                onChanged: (value) {
                                  provider.setShowFatherName(value);
                                  setState(() {});
                                }),
                          ],
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("بکار گیری متاهل ها در لوح پستی"),
                            CupertinoSwitch(
                                mouseCursor: SwitchWidgetStateProperty(),
                                value: provider.useMarried(),
                                onChanged: (value) {
                                  provider.setUseMarried(value);
                                  setState(() {});
                                }),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                  CupertinoListSection(
                    backgroundColor: AppThemeProvider.backgroundColor,
                    separatorColor: Colors.transparent,
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated,
                        borderRadius: BorderRadius.circular(3)),
                    header: const Text('ضریب استحقاق'),
                    children: [
                      Form(
                        key: _formMultiplier,
                        child: CupertinoTextFormFieldRow(
                          initialValue:
                              provider.getMultiplierOfTheMonth().toString(),
                          placeholder: 'ضریب استحقاق',
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (_formMultiplier.currentState!.validate()) {
                              final num = double.parse(value);
                              provider.setMultiplierOfTheMonth(num);
                            }
                          },
                          validator: (value) {
                            return double.tryParse(value!) == null
                                ? 'مقدار نامعتبر'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
      ),
    );
  }
}
