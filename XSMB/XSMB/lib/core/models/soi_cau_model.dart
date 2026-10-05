class CauItem {
  final String pair;
  final int count;
  final List<String> positions;
  final bool isGold;

  CauItem({
    required this.pair,
    required this.count,
    this.positions = const [],
    this.isGold = false,
  });

  factory CauItem.fromJson(Map<String, dynamic> json) {
    return CauItem(
      pair: json['pair'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      positions: (json['positions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isGold: json['isGold'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'pair': pair,
        'count': count,
        'positions': positions,
        'isGold': isGold,
      };
}

class BridgePosition {
  final String position; // e.g. "85x105"
  final String number;   // e.g. "92"
  final int vt1;
  final int vt2;
  final bool isMore;     // Longer than limit

  BridgePosition({
    required this.position,
    required this.number,
    required this.vt1,
    required this.vt2,
    this.isMore = false,
  });
}

class CauHistoryDay {
  final String drawDate;
  final String predictedPair;
  final String char1;
  final String char2;
  final List<String> hitNumbers;
  final Map<String, List<String>> prizeStructure;

  CauHistoryDay({
    required this.drawDate,
    required this.predictedPair,
    required this.char1,
    required this.char2,
    this.hitNumbers = const [],
    this.prizeStructure = const {},
  });
}

class CauDetail {
  final String position;
  final String date;
  final List<String> predictedNumbers;
  final int limitDays;
  final List<CauHistoryDay> historyDays;
  final String rawHtml;

  CauDetail({
    required this.position,
    required this.date,
    required this.predictedNumbers,
    required this.limitDays,
    this.historyDays = const [],
    this.rawHtml = '',
  });
}

class SoiCauResult {
  final String targetDate;
  final int limitDays;
  final int exactLimit; // 0: >= limit, 1: == limit
  final int nhay; // 1 to 5
  final bool isDb;
  final bool isLon; // true: Lộn (cả cặp), false: Không lộn (bạch thủ)
  final String? topGoldPair;
  final String? topGoldDesc;
  final int totalBridges;
  final int bridgesOverLimit;
  final int distinctPairsCount;
  final int pairsOverLimitCount;
  final List<CauItem> cauList;
  final List<BridgePosition> allPositions;
  final Map<int, List<int>> matrixConnections;
  final List<String> matrixDigits;
  final bool isFromWeb;

  SoiCauResult({
    required this.targetDate,
    required this.limitDays,
    this.exactLimit = 0,
    this.nhay = 1,
    this.isDb = false,
    this.isLon = true,
    this.topGoldPair,
    this.topGoldDesc,
    this.totalBridges = 0,
    this.bridgesOverLimit = 0,
    this.distinctPairsCount = 0,
    this.pairsOverLimitCount = 0,
    required this.cauList,
    required this.allPositions,
    this.matrixConnections = const {},
    this.matrixDigits = const [],
    this.isFromWeb = true,
  });

  factory SoiCauResult.empty({
    String targetDate = '',
    int limitDays = 3,
    int exactLimit = 0,
    int nhay = 1,
    bool isDb = false,
    bool isLon = true,
  }) {
    return SoiCauResult(
      targetDate: targetDate,
      limitDays: limitDays,
      exactLimit: exactLimit,
      nhay: nhay,
      isDb: isDb,
      isLon: isLon,
      totalBridges: 0,
      bridgesOverLimit: 0,
      distinctPairsCount: 0,
      pairsOverLimitCount: 0,
      cauList: [],
      allPositions: [],
      matrixConnections: const {},
      matrixDigits: const [],
      isFromWeb: false,
    );
  }
}
