import 'package:flutter/cupertino.dart';
import 'package:section_management/models/force.dart';

class ForceProvider extends ChangeNotifier {
  late Force _force;

  set force(Force force) {
    _force = force;
    notifyListeners();
  }

  Force get force => _force;
}
