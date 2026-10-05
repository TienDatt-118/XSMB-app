
import 'lib/core/models/models.dart';
import 'lib/core/models/deep_analysis_model.dart';

BoSoAnalysis analyzeBoSo(String name, bool Function(String) condition, List<LotteryResult> history) {
  int currentInterval = 0;
  int maxGan = 0;
  String maxGanFrom = '';
  String maxGanTo = '';
  String lastHitDate = history.isNotEmpty ? history.first.drawDate : '';
  List<GanInterval> allGans = [];
  int hitCount = 0;

  for (int i = 0; i < history.length; i++) {
    final res = history[i];
    final db = res.db;
    if (db.length < 2) continue;
    final spec = db.substring(db.length - 2);
    
    if (condition(spec)) {
      hitCount++;
      if (currentInterval > 0) {
        allGans.add(GanInterval(days: currentInterval, fromDate: lastHitDate, toDate: res.drawDate));
        if (currentInterval > maxGan) {
          maxGan = currentInterval;
          maxGanFrom = lastHitDate;
          maxGanTo = res.drawDate;
        }
      }
      currentInterval = 0;
      lastHitDate = res.drawDate;
    } else {
      if (lastHitDate.isEmpty && i == 0) lastHitDate = res.drawDate;
      currentInterval++;
    }
  }
  
  // Sort allGans descending by date
  allGans = allGans.reversed.toList();
  
  List<GanInterval> historicalGans = allGans.where((g) => g.days >= 15).toList();
  
  double ratio = history.isNotEmpty ? (hitCount / history.length * 100) : 0.0;
  String ratioStr = '${ratio.toStringAsFixed(2)}%';

  return BoSoAnalysis(
    name: name,
    currentGan: currentInterval,
    maxGan: maxGan,
    maxGanFrom: maxGanFrom,
    maxGanTo: maxGanTo,
    ratio: ratioStr,
    historicalGans: historicalGans,
    allGans: allGans,
  );
}

