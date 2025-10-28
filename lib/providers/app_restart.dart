import 'package:flutter/cupertino.dart';

class AppRestartProvider extends ChangeNotifier {
  void restart() {
    notifyListeners();
  }
}
