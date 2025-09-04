import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:section_management/screens/home_screen.dart';
import 'package:section_management/theme.dart';

class LoginScreen extends StatefulWidget {
  final String correctPassword;

  const LoginScreen({super.key, required this.correctPassword});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.zero,
        leading: CloseWindowButton(
          colors: WindowButtonColors(
              iconNormal: Colors.white,
              mouseDown: Colors.red,
              mouseOver: DarkTheme.backgroundColorActivated),
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
                  autofocus: true,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: DarkTheme.backgroundColorDeActivated),
                  onFieldSubmitted: (_) => _on_login_btn(),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == widget.correctPassword) {
                      return null;
                    }
                    return 'رمز عبور اشتباه است';
                  },
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
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
    }
  }
}
