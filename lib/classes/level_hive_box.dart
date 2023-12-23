import 'package:blue_chat_v1/classes/levels.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LevelHiveBox extends ChangeNotifier {
  final Box<Level> _box;

  LevelHiveBox(this._box);

  Future<void> updateLevel(Level level) async {
    await _box.put(level.value, level);
    await level.save();
  }

  ///Returns true if the level does not exist and false if it already exists
  Future<bool> addNewLevel(Level level) async {
    final checkLevel = _box.get(level.value);
    if (checkLevel == null) {
      await _box.put(level.value, level);
      await level.save();
      return true;
    }
    return false;
  }

  bool get isEmpty {
    final iLevels = _box.values.toList();
    return iLevels.isEmpty;
  }

  Future<List<Level>?> get getAllLevels async {
    final iLevels = _box.values.toList();

    if (iLevels.isEmpty) {
      for (var i = 200; i <= 500; i += 100) {
        final level = Level(
          value: i.toString(),
          semester1: [],
          semester2: [],
        );
        await addNewLevel(level);
      }
    }

    return _box.values.toList();
  }

  List<Level> get getAllLevelsSync => _box.values.toList();
  

  Level? getLevel(String levelNumber) {
    return _box.get(levelNumber);
  }

  List<Course>? firstSemester(String levelNumber) {
    final level = _box.get(levelNumber)!;
    return level.semester1;
  }

  List<Course>? secondSemester(String levelNumber) {
    final level = _box.get(levelNumber)!;
    return level.semester2;
  }
}
