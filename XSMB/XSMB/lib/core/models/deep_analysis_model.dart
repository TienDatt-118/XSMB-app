class GanInterval {
  final int days;
  final String fromDate;
  final String toDate;

  GanInterval({
    required this.days,
    required this.fromDate,
    required this.toDate,
  });
}

class BoSoAnalysis {
  final String name;
  final int currentGan;
  final int maxGan;
  final String maxGanFrom;
  final String maxGanTo;
  final String ratio; // Tỷ lệ nổ gan, e.g. "20%"
  final List<GanInterval> historicalGans; // Danh sách các lần gan >= 15 ngày
  final List<GanInterval> allGans; // Lịch sử toàn bộ

  BoSoAnalysis({
    required this.name,
    required this.currentGan,
    required this.maxGan,
    required this.maxGanFrom,
    required this.maxGanTo,
    required this.ratio,
    required this.historicalGans,
    required this.allGans,
  });
}

class DeepAnalysisData {
  final List<BoSoAnalysis> analyses;

  DeepAnalysisData({
    required this.analyses,
  });
}
