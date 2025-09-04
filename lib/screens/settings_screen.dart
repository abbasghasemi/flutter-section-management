import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _driverCountController = TextEditingController();
  final GlobalKey<FormState> _formDriver = GlobalKey<FormState>();
  final GlobalKey<FormState> _formPasswd = GlobalKey<FormState>();
  String _passwd = '';

  @override
  void initState() {
    super.initState();
    _driverCountController.text =
        Provider.of<AppProvider>(context, listen: false).driverCount.toString();
    SharedPreferences.getInstance().then((v) {
      {
        _passwd = v.getString("password") ?? '1234';
      }
    });
  }

  Future<void> _savePassword(String newPassword) async {
    _passwd = newPassword;
    _passwordController.clear();
    _oldPasswordController.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPassword);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('تنظیمات'),
            Form(
              key: _formPasswd,
              child: CupertinoListSection(
                backgroundColor: DarkTheme.backgroundColor,
                separatorColor: Colors.transparent,
                decoration: BoxDecoration(
                    color: DarkTheme.backgroundColorDeActivated,
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
                      if (_oldPasswordController.text != _passwd) {
                        return 'رمز عبور قدیم اشتباه است';
                      }
                      return null;
                    },
                  ),
                  Divider(),
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
                                    _savePassword(_passwordController.text);
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
              backgroundColor: DarkTheme.backgroundColor,
              separatorColor: Colors.transparent,
              decoration: BoxDecoration(
                  color: CupertinoColors.quaternaryLabel,
                  borderRadius: BorderRadius.circular(3)),
              header: const Text('تعداد رانندگان'),
              children: [
                Form(
                  key: _formDriver,
                  child: CupertinoTextFormFieldRow(
                    controller: _driverCountController,
                    placeholder: 'تعداد رانندگان',
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == '1' || value == '2') {
                        return null;
                      }
                      return 'تعداد رانندگان باید 1 یا 2 باشد';
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CupertinoButton.filled(
                    child: const Text('ذخیره تعداد رانندگان'),
                    onPressed: () {
                      if (_formDriver.currentState!.validate()) {
                        final num = int.tryParse(_driverCountController.text);
                        provider.setDriverCount(num!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
