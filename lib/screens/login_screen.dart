import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:section_management/providers/app_provider.dart';
import 'package:section_management/providers/app_theme.dart';
import 'package:section_management/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.zero,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: CloseWindowButton(
            colors: WindowButtonColors(
              mouseOver: Colors.red,
              mouseDown: Colors.redAccent,
              iconNormal: AppThemeProvider.textTitleColor,
              iconMouseOver: Colors.white,
            ),
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('رمز عبور را وارد کنید'),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: CupertinoTextFormFieldRow(
                  focusNode: _focus,
                  autofocus: true,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: AppThemeProvider.backgroundColorDeActivated),
                  onFieldSubmitted: (_) => _on_login_btn(),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == context.read<AppProvider>().getPassword()) {
                      return null;
                    }
                    return 'رمز عبور اشتباه است';
                  },
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                mouseCursor: SystemMouseCursors.click,
                child: const Text("ورود"),
                onPressed: _on_login_btn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _on_login_btn() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _focus.requestFocus();
    }
  }
}
