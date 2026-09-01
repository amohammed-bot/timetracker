// Plain data classes that mirror what the backend sends back.

class Category {
  final int id;
  final String name;
  final String color;

  Category({required this.id, required this.name, required this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      color: (json['color'] as String?) ?? '#4F46E5',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
}

class RunningTimer {
  final int id;
  final int categoryId;
  final DateTime startedAt;

  RunningTimer({
    required this.id,
    required this.categoryId,
    required this.startedAt,
  });

  factory RunningTimer.fromJson(Map<String, dynamic> json) {
    return RunningTimer(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'started_at': startedAt.toIso8601String(),
      };
}

class TimeEntry {
  final int id;
  final int categoryId;
  final String categoryName;
  final String color;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int seconds;

  TimeEntry({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.startedAt,
    required this.endedAt,
    required this.seconds,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      categoryName: (json['category_name'] as String?) ?? 'Unknown',
      color: (json['color'] as String?) ?? '#4F46E5',
      startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String).toLocal()
          : null,
      seconds: json['seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'color': color,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'seconds': seconds,
      };
}

class CategoryStat {
  final int categoryId;
  final String name;
  final String color;
  final int totalSeconds;

  CategoryStat({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.totalSeconds,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      color: (json['color'] as String?) ?? '#4F46E5',
      totalSeconds: json['total_seconds'] as int,
    );
  }
}

class Stats {
  final String period;
  final int totalSeconds;
  final List<CategoryStat> categories;

  Stats({
    required this.period,
    required this.totalSeconds,
    required this.categories,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      period: json['period'] as String,
      totalSeconds: json['total_seconds'] as int,
      categories: (json['categories'] as List)
          .map((c) => CategoryStat.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
