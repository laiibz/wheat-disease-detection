import 'package:flutter/material.dart';

class NavigationService with ChangeNotifier {
  int _currentIndex = 0;
  String _historyFilter = "";

  int get currentIndex => _currentIndex;
  String get historyFilter => _historyFilter;

  void setIndex(int index, {String filter = ""}) {
    _currentIndex = index;
    _historyFilter = filter;
    notifyListeners();
  }

  void clearFilter() {
    _historyFilter = "";
    notifyListeners();
  }
}
