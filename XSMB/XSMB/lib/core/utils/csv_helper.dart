import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class CsvHelper {
  static Future<void> appendResultToCsv(LotteryResult result) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/xsmb_database.csv';
      final file = File(path);

      List<dynamic> row = [
        result.drawDate,
        result.db,
        result.g1,
        result.g2.join('-'),
        result.g3.join('-'),
        result.g4.join('-'),
        result.g5.join('-'),
        result.g6.join('-'),
        result.g7.join('-'),
      ];

      String csvData = const ListToCsvConverter().convert([row]);

      if (!await file.exists()) {
        List<dynamic> header = ['Ngay', 'DB', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7'];
        String headerCsv = const ListToCsvConverter().convert([header]);
        await file.writeAsString('$headerCsv\n$csvData');
      } else {
        await file.writeAsString('\n$csvData', mode: FileMode.append);
      }
      
      debugPrint('Đã tự động lưu kết quả ngày ${result.drawDate} vào CSV: $path');
    } catch (e) {
      debugPrint('Lỗi khi ghi CSV: $e');
    }
  }

  static Future<void> shareCsvFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/xsmb_database.csv';
      final file = File(path);

      if (await file.exists()) {
        await Share.shareXFiles([XFile(path)], text: 'Dữ liệu XSMB CSV');
      } else {
        debugPrint('File CSV chưa tồn tại để chia sẻ!');
      }
    } catch (e) {
      debugPrint('Lỗi khi chia sẻ CSV: $e');
    }
  }
}
