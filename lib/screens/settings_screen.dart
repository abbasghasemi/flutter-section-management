import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _driverCountController = TextEditingController();
  final TextEditingController _multiplierOfTheMonthController =
      TextEditingController();
  final GlobalKey<FormState> _formMultiplier = GlobalKey<FormState>();
  final GlobalKey<FormState> _formDriver = GlobalKey<FormState>();
  final GlobalKey<FormState> _formPasswd = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _driverCountController.text =
        appProvider.driverCount.toString();
    _multiplierOfTheMonthController.text = appProvider.getMultiplierOfTheMonth().toString();
  }

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
                  Text('تنظیمات - دفعات بارگزاری دیتابیس ${provider.totalImportDatabase()}'),
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
                        Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CupertinoButton.filled(
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
                                      CupertinoDialogAction(
                                        child: const Text('لغو'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      CupertinoDialogAction(
                                        child: const Text('تأیید'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _savePassword(
                                              _passwordController.text);
                                        },
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
                  CupertinoListSection(
                    backgroundColor: AppThemeProvider.backgroundColor,
                    separatorColor: Colors.transparent,
                    decoration: BoxDecoration(
                        color: AppThemeProvider.backgroundColorDeActivated,
                        borderRadius: BorderRadius.circular(3)),
                    header: const Text('لوح پستی'),
                    children: [
                      Form(
                        key: _formDriver,
                        child: CupertinoTextFormFieldRow(
                          controller: _driverCountController,
                          placeholder: 'تعداد رانندگان',
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == '1' || value == '2') {
                              return null;
                            }
                            return 'تعداد رانندگان باید 1 یا 2 باشد';
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CupertinoButton.filled(
                          child: const Text('ذخیره تعداد رانندگان'),
                          onPressed: () {
                            if (_formDriver.currentState!.validate()) {
                              final num =
                                  int.parse(_driverCountController.text);
                              provider.setDriverCount(num);
                            }
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
                            CupertinoSwitch(value: provider.allowFilterMaxUsage(), onChanged: (value) {
                              provider.setAllowFilterMaxUsage(value);
                              setState(() {

                              });
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
                            CupertinoSwitch(value: provider.allowFilterUnitPriority(), onChanged: (value) {
                              provider.setAllowFilterUnitPriority(value);
                              setState(() {

                              });
                            }),
                          ],
                        ),
                      )
                      ,Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("نمایش نام پدر در لوح پستی"),
                            CupertinoSwitch(value: provider.showFatherName(), onChanged: (value) {
                              provider.setShowFatherName(value);
                              setState(() {

                              });
                            }),
                          ],
                        ),
                      )
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
                          controller: _multiplierOfTheMonthController,
                          placeholder: 'ضریب استحقاق',
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]"))
                          ],
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            return double.tryParse(value!) == null
                                ? 'مقدار نامعتبر'
                                : null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CupertinoButton.filled(
                          child: const Text('ذخیره مضرب استحقاق'),
                          onPressed: () {
                            if (_formMultiplier.currentState!.validate()) {
                              final num = double.parse(
                                  _multiplierOfTheMonthController.text);
                              provider.setMultiplierOfTheMonth(num);
                            }
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
