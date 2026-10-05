import 'dart:io';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

void main() async {
  final file = File('assets/db/xsmb_history.csv');
  if (!await file.exists()) {
    print('Không tìm thấy file assets/db/xsmb_history.csv');
    return;
  }

  // Đọc ngày cuối cùng trong file
  final lines = await file.readAsLines();
  final validLines = lines.where((line) => line.trim().isNotEmpty).toList();
  if (validLines.isEmpty) return;
  final lastLine = validLines.last;
  final lastDateStr = lastLine.split(',').first;
  
  DateTime lastDate;
  try {
    lastDate = DateTime.parse(lastDateStr);
  } catch (e) {
    print('Lỗi đọc ngày cuối: $lastDateStr');
    return;
  }

  print('Ngày cuối cùng trong CSV là: $lastDateStr');
  
  final now = DateTime.now();
  final targetDate = DateTime(now.year, now.month, now.day);
  
  if (lastDate.isAtSameMomentAs(targetDate) || lastDate.isAfter(targetDate)) {
    print('Dữ liệu đã cập nhật mới nhất!');
    return;
  }

  final dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));

  Future<List<String>?> scrapeDate(DateTime date) async {
    final d = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = 'https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac/$d.html';
    
    try {
      final response = await dio.get(url);
      final document = parse(response.data);
      
      String extractPrize(String className) {
        final elements = document.getElementsByClassName(className);
        if (elements.isEmpty) return '';
        return elements.first.text.replaceAll('-', ',').replaceAll(' ', '').trim();
      }

      List<String> extractList(String className) {
        final text = extractPrize(className);
        if (text.isEmpty) return [];
        final elements = document.getElementsByClassName(className);
        if (elements.isEmpty) return [];
        final divs = elements.first.querySelectorAll('div');
        if (divs.isNotEmpty) {
           return divs.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
        }
        return text.split(',').where((e) => e.isNotEmpty).toList();
      }
      
      final db = extractPrize('giaidb');
      final g1 = extractPrize('giai1');
      
      if (db.isEmpty && g1.isEmpty) {
        return null;
      }
      
      // Bắt buộc phải có cả DB thì mới lưu (để tránh lưu kết quả đang quay dở)
      if (db.isEmpty) {
        return null;
      }

      // KIỂM TRA QUAN TRỌNG: Đảm bảo web đang hiển thị đúng ngày yêu cầu
      // Nếu không, nó đang hiển thị ngày hôm qua vì hôm nay chưa có
      bool dateMatches = false;
      final titleElements = document.getElementsByClassName('title');
      for (var el in titleElements) {
        if (el.text.contains(d.replaceAll('-', '/'))) {
          dateMatches = true;
          break;
        }
      }

      if (!dateMatches) {
        return null;
      }

      final g2 = extractList('giai2');
      final g3 = extractList('giai3');
      final g4 = extractList('giai4');
      final g5 = extractList('giai5');
      final g6 = extractList('giai6');
      final g7 = extractList('giai7');

      final dateFmt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      List<String> row = [dateFmt, db, g1];
      row.addAll(g2);
      row.addAll(g3);
      row.addAll(g4);
      row.addAll(g5);
      row.addAll(g6);
      row.addAll(g7);
      
      // Đảm bảo đủ 28 cột như CSV cũ
      while (row.length < 28) row.add('');
      
      return row.take(28).toList();
    } catch (e) {
      return null;
    }
  }

  // Cào từ ngày tiếp theo đến hôm nay
  DateTime current = lastDate.add(Duration(days: 1));
  while (current.isBefore(targetDate) || current.isAtSameMomentAs(targetDate)) {
    print('Đang cào dữ liệu ngày: ${current.year}-${current.month}-${current.day}...');
    final row = await scrapeDate(current);
    if (row != null) {
      final csvLine = row.join(',');
      await file.writeAsString('\n$csvLine', mode: FileMode.append);
      print('=> Đã lưu vào xsmb_history.csv!');
    } else {
      print('=> Không có dữ liệu hoặc lỗi mạng.');
    }
    
    current = current.add(Duration(days: 1));
    await Future.delayed(Duration(milliseconds: 500)); // Tránh bị block
  }
  
  print('Hoàn thành cập nhật CSV trên máy tính!');
}
