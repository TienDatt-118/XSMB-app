class LotoGanItem {
  final String number;
  final int days;

  const LotoGanItem({
    required this.number,
    required this.days,
  });

  factory LotoGanItem.fromMap(Map<String, dynamic> map) {
    return LotoGanItem(
      number: map['number']?.toString() ?? '',
      days: int.tryParse(map['days']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'number': number, 'days': days};
}

class LotoFrequencyItem {
  final String number;
  final int count;

  const LotoFrequencyItem({
    required this.number,
    required this.count,
  });

  factory LotoFrequencyItem.fromMap(Map<String, dynamic> map) {
    return LotoFrequencyItem(
      number: map['number']?.toString() ?? '',
      count: int.tryParse(map['count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'number': number, 'count': count};
}

class LeadingGanItem {
  final String number;
  final int currentDays;
  final int maxDays;
  final String fromDate;
  final String toDate;

  const LeadingGanItem({
    required this.number,
    required this.currentDays,
    required this.maxDays,
    required this.fromDate,
    required this.toDate,
  });

  factory LeadingGanItem.fromMap(Map<String, dynamic> map) {
    return LeadingGanItem(
      number: map['number']?.toString() ?? '',
      currentDays: int.tryParse(map['currentDays']?.toString() ?? '0') ?? 0,
      maxDays: int.tryParse(map['maxDays']?.toString() ?? '0') ?? 0,
      fromDate: map['fromDate']?.toString() ?? '',
      toDate: map['toDate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'number': number,
    'currentDays': currentDays,
    'maxDays': maxDays,
    'fromDate': fromDate,
    'toDate': toDate,
  };
}

class DeGanItem {
  final String number;
  final int days;

  const DeGanItem({
    required this.number,
    required this.days,
  });

  factory DeGanItem.fromMap(Map<String, dynamic> map) {
    return DeGanItem(
      number: map['number']?.toString() ?? '',
      days: int.tryParse(map['days']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'number': number, 'days': days};
}

class GanTongItem {
  final int tong;
  final int days;
  final List<String> numbers;

  const GanTongItem({
    required this.tong,
    required this.days,
    required this.numbers,
  });

  factory GanTongItem.fromMap(Map<String, dynamic> map) {
    return GanTongItem(
      tong: int.tryParse(map['tong']?.toString() ?? '0') ?? 0,
      days: int.tryParse(map['days']?.toString() ?? '0') ?? 0,
      numbers: (map['numbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'tong': tong,
    'days': days,
    'numbers': numbers,
  };
}

class GanChamItem {
  final int cham;
  final int days;
  final List<String> numbers;

  const GanChamItem({
    required this.cham,
    required this.days,
    required this.numbers,
  });

  factory GanChamItem.fromMap(Map<String, dynamic> map) {
    return GanChamItem(
      cham: int.tryParse(map['cham']?.toString() ?? '0') ?? 0,
      days: int.tryParse(map['days']?.toString() ?? '0') ?? 0,
      numbers: (map['numbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'cham': cham,
    'days': days,
    'numbers': numbers,
  };
}

class QuickStatsData {
  final String targetDate;
  final List<LotoGanItem> lotoGanList;
  final List<LotoFrequencyItem> lotoFrequencyList;
  final LeadingGanItem? leadingGan;
  final List<DeGanItem> deGanList;
  final List<GanTongItem> ganTongList;
  final List<GanChamItem> ganChamList;
  final String topTongDesc;
  final String topChamDesc;
  final bool isFromWeb;

  const QuickStatsData({
    required this.targetDate,
    required this.lotoGanList,
    required this.lotoFrequencyList,
    this.leadingGan,
    required this.deGanList,
    required this.ganTongList,
    required this.ganChamList,
    required this.topTongDesc,
    required this.topChamDesc,
    this.isFromWeb = true,
  });

  factory QuickStatsData.fromMap(Map<String, dynamic> map) {
    return QuickStatsData(
      targetDate: map['targetDate']?.toString() ?? '',
      lotoGanList: (map['lotoGanList'] as List<dynamic>?)
              ?.map((e) => LotoGanItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lotoFrequencyList: (map['lotoFrequencyList'] as List<dynamic>?)
              ?.map((e) => LotoFrequencyItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      leadingGan: map['leadingGan'] != null
          ? LeadingGanItem.fromMap(map['leadingGan'] as Map<String, dynamic>)
          : null,
      deGanList: (map['deGanList'] as List<dynamic>?)
              ?.map((e) => DeGanItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      ganTongList: (map['ganTongList'] as List<dynamic>?)
              ?.map((e) => GanTongItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      ganChamList: (map['ganChamList'] as List<dynamic>?)
              ?.map((e) => GanChamItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      topTongDesc: map['topTongDesc']?.toString() ?? '',
      topChamDesc: map['topChamDesc']?.toString() ?? '',
      isFromWeb: map['isFromWeb'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'targetDate': targetDate,
    'lotoGanList': lotoGanList.map((e) => e.toMap()).toList(),
    'lotoFrequencyList': lotoFrequencyList.map((e) => e.toMap()).toList(),
    'leadingGan': leadingGan?.toMap(),
    'deGanList': deGanList.map((e) => e.toMap()).toList(),
    'ganTongList': ganTongList.map((e) => e.toMap()).toList(),
    'ganChamList': ganChamList.map((e) => e.toMap()).toList(),
    'topTongDesc': topTongDesc,
    'topChamDesc': topChamDesc,
    'isFromWeb': isFromWeb,
  };
}
