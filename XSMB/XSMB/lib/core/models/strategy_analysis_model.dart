/// Data models for strategy-based deep analysis.
/// Mirrors the Laravel $excelData structure from phan-tich.blade.php
library;

class StrategyHistoryRow {
  final String date;   // dd/MM/yyyy
  final String val;    // 2-digit value, e.g. "42"
  final String pattern; // Column name, e.g. "TN"

  StrategyHistoryRow({required this.date, required this.val, required this.pattern});
}

class StrategyGanCycle {
  final int length;
  final String from;   // dd/MM/yyyy
  final String to;     // dd/MM/yyyy

  StrategyGanCycle({required this.length, required this.from, required this.to});
}

class FieldAnalysis {
  final String name;      // "ĐẦU ĐẶC BIỆT", "CUỐI ĐẶC BIỆT", ...
  final String fieldKey;  // gdb_first2, gdb_last2, g1_first2, g1_last2
  final Map<String, int> gan;              // column -> current gan days
  final Map<String, int> maxGan;           // column -> max gan days
  final Map<String, String> maxGanDates;   // column -> "dd/MM/yyyy - dd/MM/yyyy"
  final List<StrategyHistoryRow> history;  // Last 30 days (newest first)
  final Map<String, List<StrategyGanCycle>> ganCycles; // column -> sorted cycles

  FieldAnalysis({
    required this.name,
    required this.fieldKey,
    required this.gan,
    required this.maxGan,
    required this.maxGanDates,
    required this.history,
    required this.ganCycles,
  });
}

class StrategyData {
  final String name;               // "To / Nhỏ"
  final String strKey;             // "tn"
  final List<String> cols;         // ["TT","NN","TN","NT"]
  final Map<String, FieldAnalysis> fields; // gdb_first2, gdb_last2, g1_first2, g1_last2

  StrategyData({
    required this.name,
    required this.strKey,
    required this.cols,
    required this.fields,
  });
}

/// Column code → full display name mapping
const Map<String, String> colDisplayNames = {
  // Mode 25: To/Nhỏ
  'TT': 'To To', 'NN': 'Nhỏ Nhỏ', 'TN': 'To Nhỏ', 'NT': 'Nhỏ To',
  // Mode 25: Chẵn/Lẻ
  'CC': 'Chẵn Chẵn', 'LL': 'Lẻ Lẻ', 'LC': 'Lẻ Chẵn', 'CL': 'Chẵn Lẻ',
  // Mode 25: To-Nhỏ / Chẵn-Lẻ
  'TC': 'To Chẵn', 'TL': 'To Lẻ', 'NC': 'Nhỏ Chẵn', 'NL': 'Nhỏ Lẻ',
  // Mode 25: Chẵn-Lẻ / To-Nhỏ
  'CT': 'Chẵn To', 'LT': 'Lẻ To', 'CN': 'Chẵn Nhỏ', 'LN': 'Lẻ Nhỏ',
  // Mode 25: Chia 4
  'Dư 0': 'Dư 0', 'Dư 1': 'Dư 1', 'Dư 2': 'Dư 2', 'Dư 3': 'Dư 3',
  // Mode 25: Dải 25
  '00-24': 'Dải 00-24', '25-49': 'Dải 25-49', '50-74': 'Dải 50-74', '75-99': 'Dải 75-99',
  // Mode 20: Dải số
  'D0_19': 'Dải 00-19', 'D20_39': 'Dải 20-39', 'D40_59': 'Dải 40-59', 'D60_79': 'Dải 60-79', 'D80_99': 'Dải 80-99',
  // Mode 20: Chia 5
  'DU0': 'Dư 0', 'DU1': 'Dư 1', 'DU2': 'Dư 2', 'DU3': 'Dư 3', 'DU4': 'Dư 4',
  // Mode 20: Bóng Đầu
  'DAU05': 'Đầu 0-5', 'DAU16': 'Đầu 1-6', 'DAU27': 'Đầu 2-7', 'DAU38': 'Đầu 3-8', 'DAU49': 'Đầu 4-9',
  // Mode 20: Bóng Đuôi
  'DUOI05': 'Đuôi 0-5', 'DUOI16': 'Đuôi 1-6', 'DUOI27': 'Đuôi 2-7', 'DUOI38': 'Đuôi 3-8', 'DUOI49': 'Đuôi 4-9',
  // Mode 20: Bóng Tổng
  'TONG05': 'Tổng 0-5', 'TONG16': 'Tổng 1-6', 'TONG27': 'Tổng 2-7', 'TONG38': 'Tổng 3-8', 'TONG49': 'Tổng 4-9',
  // Mode 20: Bóng Hiệu
  'HIEU05': 'Hiệu 0-5', 'HIEU19': 'Hiệu 1-9', 'HIEU28': 'Hiệu 2-8', 'HIEU37': 'Hiệu 3-7', 'HIEU46': 'Hiệu 4-6',
};
