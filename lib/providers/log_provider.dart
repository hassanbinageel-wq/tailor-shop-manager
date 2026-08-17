import 'package:flutter/material.dart';

import '../models/activity_log.dart';
import '../repositories/log_repository.dart';

class LogProvider extends ChangeNotifier {
  final LogRepository _repo = LogRepository();

  List<ActivityLog> items = [];
  bool busy = false;

  Future<void> load() async {
    busy = true;
    notifyListeners();
    items = await _repo.getAll();
    busy = false;
    notifyListeners();
  }

  Future<void> clear() async {
    await _repo.clear();
    await load();
  }
}
