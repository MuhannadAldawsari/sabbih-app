class AdhkarCategory {
  final int id;
  final String category;
  final List<AdhkarItem> items;

  const AdhkarCategory({
    required this.id,
    required this.category,
    required this.items,
  });

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) {
    final rawArray = json['array'] as List<dynamic>? ?? [];
    return AdhkarCategory(
      id: json['id'] as int,
      category: json['category'] as String,
      items: rawArray.map((e) => AdhkarItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  int get totalItems => items.length;
}

class AdhkarItem {
  final int id;
  final String text;
  final List<int> countStages;
  final String fadhelShort;
  final String dalil;
  final String summary;
  final String narrator;
  final String almohdith;
  final String source;

  const AdhkarItem({
    required this.id,
    required this.text,
    required this.countStages,
    this.fadhelShort = '',
    this.dalil = '',
    this.summary = '',
    this.narrator = '',
    this.almohdith = '',
    this.source = '',
  });

  factory AdhkarItem.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    List<int> stages;
    if (rawCount is List) {
      stages = rawCount.map((e) => e as int).toList();
    } else if (rawCount is int) {
      stages = [rawCount];
    } else {
      stages = [1];
    }

    return AdhkarItem(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      countStages: stages,
      fadhelShort: json['fadhelShort'] as String? ?? '',
      dalil: json['dalil'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      narrator: json['narrator'] as String? ?? '',
      almohdith: json['almohdith'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  int get totalCount => countStages.isNotEmpty ? countStages.last : 1;
  
  bool get hasMultipleStages => countStages.length > 1;
  
  bool get hasFadhelShort => fadhelShort.isNotEmpty;
  
  bool get hasSource => source.isNotEmpty;
  
  bool get hasDetails => 
      dalil.isNotEmpty || 
      summary.isNotEmpty || 
      narrator.isNotEmpty || 
      almohdith.isNotEmpty || 
      source.isNotEmpty;
}

class AdhkarProgress {
  final int categoryId;
  final int itemId;
  final int currentTaps;
  final int currentStage;
  final bool isCompleted;

  const AdhkarProgress({
    required this.categoryId,
    required this.itemId,
    this.currentTaps = 0,
    this.currentStage = 0,
    this.isCompleted = false,
  });

  AdhkarProgress copyWith({
    int? currentTaps,
    int? currentStage,
    bool? isCompleted,
  }) {
    return AdhkarProgress(
      categoryId: categoryId,
      itemId: itemId,
      currentTaps: currentTaps ?? this.currentTaps,
      currentStage: currentStage ?? this.currentStage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'itemId': itemId,
    'currentTaps': currentTaps,
    'currentStage': currentStage,
    'isCompleted': isCompleted,
  };

  factory AdhkarProgress.fromJson(Map<String, dynamic> json) {
    return AdhkarProgress(
      categoryId: json['categoryId'] as int,
      itemId: json['itemId'] as int,
      currentTaps: json['currentTaps'] as int? ?? 0,
      currentStage: json['currentStage'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
