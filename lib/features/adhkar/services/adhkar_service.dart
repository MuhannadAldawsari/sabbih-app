import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabbh/features/adhkar/models/adhkar_model.dart';

class AdhkarService {
  static const _progressKeyPrefix = 'adhkar_progress_';
  static const _lastResetKey = 'adhkar_last_reset_date';
  
  List<AdhkarCategory>? _cachedCategories;

  Future<List<AdhkarCategory>> loadAllCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    
    final jsonString = await rootBundle.loadString('assets/adhkar.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    
    _cachedCategories = jsonList
        .map((e) => AdhkarCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return _cachedCategories!;
  }

  Future<AdhkarCategory?> getCategoryById(int id) async {
    final categories = await loadAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<AdhkarCategory?> getCategoryByName(String name) async {
    final categories = await loadAllCategories();
    try {
      return categories.firstWhere(
        (c) => c.category == name || c.category.contains(name),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, AdhkarProgress>> loadProgress(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs, categoryId);
    
    final Map<int, AdhkarProgress> progressMap = {};
    final keys = prefs.getKeys().where(
      (k) => k.startsWith('$_progressKeyPrefix${categoryId}_'),
    );
    
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          final progress = AdhkarProgress.fromJson(data);
          progressMap[progress.itemId] = progress;
        } catch (_) {}
      }
    }
    
    return progressMap;
  }

  Future<void> saveProgress(AdhkarProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_progressKeyPrefix${progress.categoryId}_${progress.itemId}';
    await prefs.setString(key, json.encode(progress.toJson()));
  }

  Future<void> resetCategoryProgress(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith('$_progressKeyPrefix${categoryId}_'),
    ).toList();
    
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> resetItemProgress(int categoryId, int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_progressKeyPrefix${categoryId}_$itemId';
    await prefs.remove(key);
  }

  Future<void> markAllAsRead(int categoryId, List<AdhkarItem> items) async {
    for (final item in items) {
      final progress = AdhkarProgress(
        categoryId: categoryId,
        itemId: item.id,
        currentTaps: item.totalCount,
        currentStage: item.countStages.length - 1,
        isCompleted: true,
      );
      await saveProgress(progress);
    }
  }

  Future<void> _checkDailyReset(SharedPreferences prefs, int categoryId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastResetKey = '${_lastResetKey}_$categoryId';
    final lastReset = prefs.getString(lastResetKey);
    
    if (lastReset != todayStr) {
      await resetCategoryProgress(categoryId);
      await prefs.setString(lastResetKey, todayStr);
    }
  }

  static const Map<int, String> categoryIdToName = {
    1: 'أذكار الصباح',
    2: 'أذكار المساء',
    3: 'الأذكار بعد الصلاة',
    4: 'أذكار النوم',
  };

  static String getCategoryTitle(int id) {
    return categoryIdToName[id] ?? 'أذكار';
  }
}
