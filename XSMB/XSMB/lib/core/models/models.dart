import 'dart:convert';
export 'quick_stats_model.dart';
export 'soi_cau_model.dart';

class LotteryResult {
  final String drawDate;
  final String db; // Spec Prize (1 number)
  final String g1; // G1 (1 number)
  final List<String> g2; // G2 (2 numbers)
  final List<String> g3; // G3 (6 numbers)
  final List<String> g4; // G4 (4 numbers)
  final List<String> g5; // G5 (6 numbers)
  final List<String> g6; // G6 (3 numbers)
  final List<String> g7; // G7 (4 numbers)
  final bool isLive;
  final String createdAt;

  static String _normalizeDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    // If format is dd-MM-yyyy or dd/MM/yyyy (length 10, separator at index 2 and 5)
    if (dateStr.length == 10 && (dateStr[2] == '-' || dateStr[2] == '/')) {
      final separator = dateStr[2];
      final parts = dateStr.split(separator);
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}'; // Convert to yyyy-MM-dd
      }
    }
    return dateStr;
  }

  LotteryResult({
    required String drawDate,
    required this.db,
    required this.g1,
    required this.g2,
    required this.g3,
    required this.g4,
    required this.g5,
    required this.g6,
    required this.g7,
    this.isLive = false,
    required this.createdAt,
  }) : drawDate = _normalizeDate(drawDate);

  // Flat list of all 27 numbers drawn (cached — computed once)
  late final List<String> allNumbers = _computeAllNumbers();

  List<String> _computeAllNumbers() {
    final list = <String>[];
    if (db.isNotEmpty) list.add(db);
    if (g1.isNotEmpty) list.add(g1);
    list.addAll(g2.where((e) => e.isNotEmpty));
    list.addAll(g3.where((e) => e.isNotEmpty));
    list.addAll(g4.where((e) => e.isNotEmpty));
    list.addAll(g5.where((e) => e.isNotEmpty));
    list.addAll(g6.where((e) => e.isNotEmpty));
    list.addAll(g7.where((e) => e.isNotEmpty));
    return List.unmodifiable(list);
  }

  // Cached set of all 2-digit tails for fast lookup in analysis
  late final Set<String> allLast2Digits = allNumbers
      .where((n) => n.length >= 2)
      .map((n) => n.substring(n.length - 2))
      .toSet();

  // Head and Tail statistics map for this specific result (cached — computed once)
  late final Map<int, List<int>> headStats = _computeHeadStats();
  late final Map<int, List<int>> tailStats = _computeTailStats();

  Map<int, List<int>> _computeHeadStats() {
    final map = <int, List<int>>{};
    for (int i = 0; i <= 9; i++) {
      map[i] = [];
    }
    for (var numStr in allNumbers) {
      if (numStr.length >= 2) {
        final last2 = numStr.substring(numStr.length - 2);
        final head = int.parse(last2[0]);
        final tail = int.parse(last2[1]);
        map[head]?.add(tail);
      }
    }
    return map;
  }

  Map<int, List<int>> _computeTailStats() {
    final map = <int, List<int>>{};
    for (int i = 0; i <= 9; i++) {
      map[i] = [];
    }
    for (var numStr in allNumbers) {
      if (numStr.length >= 2) {
        final last2 = numStr.substring(numStr.length - 2);
        final head = int.parse(last2[0]);
        final tail = int.parse(last2[1]);
        map[tail]?.add(head);
      }
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LotteryResult &&
          runtimeType == other.runtimeType &&
          drawDate == other.drawDate &&
          db == other.db &&
          g1 == other.g1 &&
          isLive == other.isLive;

  @override
  int get hashCode => drawDate.hashCode ^ db.hashCode ^ g1.hashCode ^ isLive.hashCode;

  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'draw_date': drawDate,
      'db': db,
      'g1': g1,
      'g2': g2.join(','),
      'g3': g3.join(','),
      'g4': g4.join(','),
      'g5': g5.join(','),
      'g6': g6.join(','),
      'g7': g7.join(','),
      'is_live': isLive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory LotteryResult.fromMap(Map<String, dynamic> map) {
    return LotteryResult(
      drawDate: map['draw_date'] as String,
      db: map['db'] as String,
      g1: map['g1'] as String,
      g2: (map['g2'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      g3: (map['g3'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      g4: (map['g4'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      g5: (map['g5'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      g6: (map['g6'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      g7: (map['g7'] as String).split(',').where((e) => e.isNotEmpty).toList(),
      isLive: (map['is_live'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  // JSON API serialization
  Map<String, dynamic> toJson() {
    return {
      'draw_date': drawDate,
      'db': db,
      'g1': g1,
      'g2': g2,
      'g3': g3,
      'g4': g4,
      'g5': g5,
      'g6': g6,
      'g7': g7,
      'is_live': isLive,
      'created_at': createdAt,
    };
  }

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) return val.split(',').where((s) => s.isNotEmpty).toList();
      return [];
    }

    return LotteryResult(
      drawDate: json['draw_date']?.toString() ?? '',
      db: json['db']?.toString() ?? '',
      g1: json['g1']?.toString() ?? '',
      g2: parseList(json['g2']),
      g3: parseList(json['g3']),
      g4: parseList(json['g4']),
      g5: parseList(json['g5']),
      g6: parseList(json['g6']),
      g7: parseList(json['g7']),
      isLive: json['is_live'] == true || json['is_live'] == 1,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

class LotteryAnalysis {
  final Map<String, List<int>> frequencies; // Number: List of positions
  final List<String> numbers25; // Top 25 numbers
  final List<String> numbers20; // Top 20 numbers
  final List<String> set4;      // Top 4 sets
  final List<String> set5;      // Top 5 sets
  final Map<String, int> modulo4; // Modulo 4 counts: { 'mod_0': 5, ... }
  final List<String> hotNumbers;  // Hot numbers suggest
  final List<String> coldNumbers; // Cold numbers suggest
  final List<String> suggestions; // Dynamic suggestions
  final String matrixHeatmapJson; // JSON representation of matrix occurrences
  
  LotteryAnalysis({
    required this.frequencies,
    required this.numbers25,
    required this.numbers20,
    required this.set4,
    required this.set5,
    required this.modulo4,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.suggestions,
    required this.matrixHeatmapJson,
  });

  factory LotteryAnalysis.fromJson(Map<String, dynamic> json) {
    Map<String, List<int>> parseFrequencies(dynamic data) {
      final map = <String, List<int>>{};
      if (data is Map) {
        data.forEach((key, val) {
          if (val is List) {
            map[key.toString()] = val.map((e) => int.parse(e.toString())).toList();
          }
        });
      }
      return map;
    }

    Map<String, int> parseMapStringInt(dynamic data) {
      final map = <String, int>{};
      if (data is Map) {
        data.forEach((key, val) {
          map[key.toString()] = int.tryParse(val.toString()) ?? 0;
        });
      }
      return map;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return LotteryAnalysis(
      frequencies: parseFrequencies(json['frequencies']),
      numbers25: parseList(json['numbers_25']),
      numbers20: parseList(json['numbers_20']),
      set4: parseList(json['set_4']),
      set5: parseList(json['set_5']),
      modulo4: parseMapStringInt(json['modulo_4']),
      hotNumbers: parseList(json['hot_numbers']),
      coldNumbers: parseList(json['cold_numbers']),
      suggestions: parseList(json['suggestions']),
      matrixHeatmapJson: json['matrix_heatmap'] is String 
          ? json['matrix_heatmap'] 
          : jsonEncode(json['matrix_heatmap'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequencies': frequencies,
      'numbers_25': numbers25,
      'numbers_20': numbers20,
      'set_4': set4,
      'set_5': set5,
      'modulo_4': modulo4,
      'hot_numbers': hotNumbers,
      'cold_numbers': coldNumbers,
      'suggestions': suggestions,
      'matrix_heatmap': matrixHeatmapJson,
    };
  }
}

class LoGanModel {
  final String number;
  final int missingDays;
  final String lastDrawnDate;
  final int maxMissingDays;

  LoGanModel({
    required this.number,
    required this.missingDays,
    required this.lastDrawnDate,
    required this.maxMissingDays,
  });

  factory LoGanModel.fromJson(Map<String, dynamic> json) {
    return LoGanModel(
      number: json['number']?.toString() ?? '',
      missingDays: int.tryParse(json['missing_days']?.toString() ?? '0') ?? 0,
      lastDrawnDate: json['last_drawn_date']?.toString() ?? '',
      maxMissingDays: int.tryParse(json['max_missing_days']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'missing_days': missingDays,
      'last_drawn_date': lastDrawnDate,
      'max_missing_days': maxMissingDays,
    };
  }
}

class HeadTailModel {
  final int digit; // 0-9
  final int count;
  final double percentage;

  HeadTailModel({
    required this.digit,
    required this.count,
    required this.percentage,
  });

  factory HeadTailModel.fromJson(Map<String, dynamic> json) {
    return HeadTailModel(
      digit: int.tryParse(json['digit']?.toString() ?? '0') ?? 0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'digit': digit,
      'count': count,
      'percentage': percentage,
    };
  }
}

class CauLoto {
  final String number;
  final int consecutiveDays;

  CauLoto({required this.number, required this.consecutiveDays});
}

class CauDacBiet {
  final String number;
  final String frequency; // e.g. "1 lần / 10 kỳ"

  CauDacBiet({required this.number, required this.frequency});
}

class Cau2Nhay {
  final String number;
  final String date;

  Cau2Nhay({required this.number, required this.date});
}

class CauStats {
  final List<CauLoto> cauLoto;
  final List<CauDacBiet> cauDacBiet;
  final List<Cau2Nhay> cau2Nhay;

  CauStats({
    required this.cauLoto,
    required this.cauDacBiet,
    required this.cau2Nhay,
  });
}

class ThongKeData {
  final List<LotteryResult> history;
  final Map<String, int> frequencies;
  final int maxFrequency;

  ThongKeData({
    required this.history,
    required this.frequencies,
    required this.maxFrequency,
  });

  factory ThongKeData.empty() {
    return ThongKeData(history: [], frequencies: {}, maxFrequency: 0);
  }
}

class LoTopItem {
  final String number;
  final int hitCount;
  final List<String> prizes;
  final int totalHistoricalHits;

  LoTopItem({
    required this.number,
    required this.hitCount,
    required this.prizes,
    required this.totalHistoricalHits,
  });
}
