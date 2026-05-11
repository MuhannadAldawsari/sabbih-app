import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sabbh/features/adhkar/models/adhkar_model.dart';
import 'package:sabbh/features/adhkar/services/adhkar_service.dart';

class AdhkarState {
  final int categoryId;
  final String categoryTitle;
  final List<AdhkarItem> items;
  final Map<int, AdhkarProgress> progressMap;
  final bool isLoading;
  final String? error;

  const AdhkarState({
    required this.categoryId,
    this.categoryTitle = '',
    this.items = const [],
    this.progressMap = const {},
    this.isLoading = false,
    this.error,
  });

  AdhkarState copyWith({
    String? categoryTitle,
    List<AdhkarItem>? items,
    Map<int, AdhkarProgress>? progressMap,
    bool? isLoading,
    String? error,
  }) {
    return AdhkarState(
      categoryId: categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      items: items ?? this.items,
      progressMap: progressMap ?? this.progressMap,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalItems => items.length;
  
  int get completedItems {
    int count = 0;
    for (final item in items) {
      final progress = progressMap[item.id];
      if (progress != null) {
        if (progress.isCompleted || progress.currentStage > 0) {
          count++;
        }
      }
    }
    return count;
  }
  
  double get completionPercentage {
    if (totalItems == 0) return 0;
    return (completedItems / totalItems) * 100;
  }
  
  bool get allCompleted => completedItems == totalItems && totalItems > 0;
}

class AdhkarCubit extends Cubit<AdhkarState> {
  final AdhkarService _service;

  AdhkarCubit({
    required int categoryId,
    AdhkarService? service,
  }) : _service = service ?? AdhkarService(),
       super(AdhkarState(categoryId: categoryId, isLoading: true));

  Future<void> loadCategory() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final category = await _service.getCategoryById(state.categoryId);
      if (category == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'لم يتم العثور على الفئة',
        ));
        return;
      }

      final progressMap = await _service.loadProgress(state.categoryId);
      
      emit(state.copyWith(
        categoryTitle: category.category,
        items: category.items,
        progressMap: progressMap,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحميل الأذكار',
      ));
    }
  }

  Future<void> incrementCounter(int itemId) async {
    final item = state.items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    
    final currentProgress = state.progressMap[itemId] ?? AdhkarProgress(
      categoryId: state.categoryId,
      itemId: itemId,
    );

    if (currentProgress.isCompleted) return;

    final newTaps = currentProgress.currentTaps + 1;
    final stages = item.countStages;
    int newStage = currentProgress.currentStage;
    bool isCompleted = false;

    if (newStage < stages.length && newTaps >= stages[newStage]) {
      if (newStage < stages.length - 1) {
        newStage++;
      } else {
        isCompleted = true;
      }
    }

    final newProgress = currentProgress.copyWith(
      currentTaps: newTaps,
      currentStage: newStage,
      isCompleted: isCompleted,
    );

    await _service.saveProgress(newProgress);

    final newMap = Map<int, AdhkarProgress>.from(state.progressMap);
    newMap[itemId] = newProgress;

    emit(state.copyWith(progressMap: newMap));
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead(state.categoryId, state.items);
    
    final newMap = <int, AdhkarProgress>{};
    for (final item in state.items) {
      newMap[item.id] = AdhkarProgress(
        categoryId: state.categoryId,
        itemId: item.id,
        currentTaps: item.totalCount,
        currentStage: item.countStages.length - 1,
        isCompleted: true,
      );
    }
    
    emit(state.copyWith(progressMap: newMap));
  }

  Future<void> resetProgress() async {
    await _service.resetCategoryProgress(state.categoryId);
    emit(state.copyWith(progressMap: {}));
  }

  Future<void> resetSingleItem(int itemId) async {
    await _service.resetItemProgress(state.categoryId, itemId);
    final newMap = Map<int, AdhkarProgress>.from(state.progressMap);
    newMap.remove(itemId);
    emit(state.copyWith(progressMap: newMap));
  }

  double getItemProgress(AdhkarItem item) {
    final progress = state.progressMap[item.id];
    if (progress == null) return 0;
    if (progress.isCompleted) return 1;
    
    final stages = item.countStages;
    final currentStage = progress.currentStage;
    
    if (currentStage >= stages.length) return 1;
    
    final stageTarget = stages[currentStage];
    final previousTarget = currentStage > 0 ? stages[currentStage - 1] : 0;
    final stageProgress = progress.currentTaps - previousTarget;
    final stageSize = stageTarget - previousTarget;
    
    if (stageSize <= 0) return 1;
    return stageProgress / stageSize;
  }

  int getCurrentTaps(int itemId) {
    return state.progressMap[itemId]?.currentTaps ?? 0;
  }

  int getCurrentStage(int itemId) {
    return state.progressMap[itemId]?.currentStage ?? 0;
  }

  bool isItemCompleted(int itemId) {
    return state.progressMap[itemId]?.isCompleted ?? false;
  }

  int getCurrentStageTarget(AdhkarItem item) {
    final progress = state.progressMap[item.id];
    final currentStage = progress?.currentStage ?? 0;
    if (currentStage < item.countStages.length) {
      return item.countStages[currentStage];
    }
    return item.totalCount;
  }
}
