import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import '../models/models.dart';

class SoiCauService {
  final Dio _dio;

  SoiCauService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                  'Referer': 'https://rongbachkim.net/soicau.html?setmode=full',
                },
              ),
            );

  /// Fetch bridges from RongBachKim
  Future<SoiCauResult?> fetchSoiCauFromWeb({
    required DateTime date,
    int limit = 5,
    int exactLimit = 0,
    int nhay = 1,
    bool isDb = false,
    bool isLon = true,
    String? searchNum,
  }) async {
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    String url;
    if (searchNum != null && searchNum.trim().isNotEmpty) {
      final cleanNum = searchNum.trim();
      url =
          'https://rongbachkim.net/soicau.php?soi&setmode=num&submit=1&timcau=${Uri.encodeComponent(cleanNum)}&limit=$limit&exactlimit=$exactLimit&lon=${isLon ? 1 : 0}&db=${isDb ? 1 : 0}&nhay=$nhay&ngay=$isoDate';
    } else {
      url =
          'https://rongbachkim.net/soicau.php?soi&setmode=full&ngay=$isoDate&limit=$limit&exactlimit=$exactLimit&lon=${isLon ? 1 : 0}&db=${isDb ? 1 : 0}&nhay=$nhay';
    }

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data.toString();
        if (html.contains('cầu') ||
            html.contains('a_cau') ||
            html.contains('matrancau') ||
            html.contains('Độ dài')) {
          return _parseSoiCauHtml(
            html: html,
            targetDate: isoDate,
            limitDays: limit,
            exactLimit: exactLimit,
            nhay: nhay,
            isDb: isDb,
            isLon: isLon,
            searchNum: searchNum,
          );
        }
      }
    } catch (e) {
      debugPrint('SoiCauService: fetchSoiCauFromWeb error: $e');
    }
    return null;
  }

  /// Parse the list of bridges
  SoiCauResult _parseSoiCauHtml({
    required String html,
    required String targetDate,
    required int limitDays,
    required int exactLimit,
    required int nhay,
    required bool isDb,
    required bool isLon,
    String? searchNum,
  }) {
    final doc = parse(html);

    // 1. Summary numbers
    int totalBridges = 0;
    int bridgesOverLimit = 0;
    int distinctPairsCount = 0;
    int pairsOverLimitCount = 0;

    for (var div in doc.querySelectorAll('div')) {
      final text = div.text.trim();
      final m1 = RegExp(r'tìm được\s*(\d+)\s*cầu').firstMatch(text);
      if (m1 != null) {
        totalBridges = int.tryParse(m1.group(1) ?? '0') ?? totalBridges;
      }
      final m2 = RegExp(r'có\s*(\d+)\s*cầu dài trên').firstMatch(text);
      if (m2 != null) {
        bridgesOverLimit = int.tryParse(m2.group(1) ?? '0') ?? bridgesOverLimit;
      }
      final m3 = RegExp(r'xuất hiện tại\s*(\d+)\s*cặp số').firstMatch(text);
      if (m3 != null) {
        distinctPairsCount = int.tryParse(m3.group(1) ?? '0') ?? distinctPairsCount;
      }
      final m4 = RegExp(r'có\s*(\d+)\s*cặp số có cầu chạy hơn').firstMatch(text);
      if (m4 != null) {
        pairsOverLimitCount = int.tryParse(m4.group(1) ?? '0') ?? pairsOverLimitCount;
      }
    }

    // 2. Top gold pair announcement (e.g. Cặp số có nhiều cầu nhất là 23,32: 7 cầu)
    String? topGoldPair;
    String? topGoldDesc;
    for (var div in doc.querySelectorAll('div')) {
      final text = div.text.trim();
      if (text.contains('Cặp số có nhiều cầu nhất')) {
        topGoldDesc = text;
        final match = RegExp(r'là\s+([0-9,\s]+):?\s*(\d+)\s*cầu').firstMatch(text);
        if (match != null) {
          topGoldPair = '${match.group(1)?.trim()} (${match.group(2)} cầu)';
        }
        break;
      }
    }

    // 3. Extract matrix positions and connections
    final matrixConnections = <int, List<int>>{};
    final matrixDigits = List<String>.filled(107, '');
    for (var span in doc.querySelectorAll('span.vt')) {
      final id = span.attributes['id'] ?? '';
      final idMatch = RegExp(r'vt_(\d+)').firstMatch(id);
      if (idMatch != null) {
        final vtIndex = int.tryParse(idMatch.group(1)!) ?? -1;
        if (vtIndex >= 0 && vtIndex < 107) {
          matrixDigits[vtIndex] = span.text.trim();
          final connections = <int>[];
          for (var c in span.classes) {
            final cMatch = RegExp(r'^vt_(\d+)$').firstMatch(c);
            if (cMatch != null) {
              final connIdx = int.tryParse(cMatch.group(1)!) ?? -1;
              if (connIdx >= 0 && connIdx != vtIndex) {
                if (!connections.contains(connIdx)) {
                  connections.add(connIdx);
                }
              }
            }
          }
          if (connections.isNotEmpty) {
            matrixConnections[vtIndex] = connections;
          }
        }
      }
    }

    // 4. Parse positions
    final allPositions = <BridgePosition>[];

    // 4A. Check for full mode: links like <a rel="55x95" class="a_cau">00</a>
    final positionLinks = doc.querySelectorAll('a.a_cau');
    for (var a in positionLinks) {
      final rel = a.attributes['rel'] ?? '';
      final numText = a.text.trim();
      final isMore = a.classes.contains('a_cau_more');

      if (rel.contains('x')) {
        final parts = rel.split('x');
        final vt1 = int.tryParse(parts[0]) ?? 0;
        final vt2 = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

        allPositions.add(BridgePosition(
          position: rel,
          number: numText,
          vt1: vt1,
          vt2: vt2,
          isMore: isMore,
        ));
      }
    }

    // 4B. Check for setmode=num mode: links like <a href="?showcau...vt=25x27...limit=7">1. Độ dài: 7 ngày, tại vị trí 25x27</a>
    if (allPositions.isEmpty) {
      final numLinks = doc.querySelectorAll('a[href*="vt="]');
      for (var a in numLinks) {
        final href = a.attributes['href'] ?? '';
        final vtMatch = RegExp(r'vt=([0-9x]+)').firstMatch(href);
        if (vtMatch != null) {
          final posStr = vtMatch.group(1)!;
          final parts = posStr.split('x');
          final vt1 = int.tryParse(parts[0]) ?? 0;
          final vt2 = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

          // Check if limit in href > limitDays
          final limitMatch = RegExp(r'limit=(\d+)').firstMatch(href);
          final hrefLimit = limitMatch != null ? int.tryParse(limitMatch.group(1)!) ?? limitDays : limitDays;
          final isMore = hrefLimit > limitDays;

          // Determine predicted number from matrixDigits if available
          String predNum = '';
          if (vt1 >= 0 && vt1 < 107 && vt2 >= 0 && vt2 < 107) {
            predNum = '${matrixDigits[vt1]}${matrixDigits[vt2]}';
          }
          if (predNum.isEmpty && searchNum != null && searchNum.isNotEmpty) {
            predNum = searchNum.split(',').first.trim();
          }

          allPositions.add(BridgePosition(
            position: posStr,
            number: predNum,
            vt1: vt1,
            vt2: vt2,
            isMore: isMore,
          ));
        }
      }
    }

    // 5. Parse repeated bridges table (Thống kê cầu lặp - table.tbl1)
    final cauList = <CauItem>[];
    final rows = doc.querySelectorAll('table.tbl1 tr');
    for (var tr in rows) {
      final col1 = tr.querySelector('td.col1');
      final col2 = tr.querySelector('td.col2');
      if (col1 != null && col2 != null) {
        final pair = col1.text.trim();
        final countText = col2.text.replaceAll(RegExp(r'[^\d]'), '');
        final count = int.tryParse(countText) ?? 0;

        if (pair.isNotEmpty && count > 0) {
          final pairNums = pair.split(',').map((e) => e.trim()).toSet();
          final posList = allPositions
              .where((p) => pairNums.contains(p.number))
              .map((p) => p.position)
              .toSet()
              .toList();

          cauList.add(CauItem(
            pair: pair,
            count: count,
            positions: posList,
            isGold: cauList.isEmpty,
          ));
        }
      }
    }

    // Fallback if table tbl1 wasn't found or was empty (e.g. In num mode)
    if (cauList.isEmpty && allPositions.isNotEmpty) {
      final mapCount = <String, List<String>>{};
      for (var pos in allPositions) {
        final num = pos.number;
        final rev = num.length == 2 ? '${num[1]}${num[0]}' : num;
        final pairKey = !isLon
            ? num
            : (num.compareTo(rev) <= 0
                ? (num == rev ? num : '$num,$rev')
                : '$rev,$num');

        mapCount.putIfAbsent(pairKey, () => []).add(pos.position);
      }

      final sortedEntries = mapCount.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

      for (var i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        cauList.add(CauItem(
          pair: entry.key,
          count: entry.value.length,
          positions: entry.value,
          isGold: i == 0,
        ));
      }
    }

    if (totalBridges == 0) totalBridges = allPositions.length;
    if (bridgesOverLimit == 0) {
      bridgesOverLimit = allPositions.where((p) => p.isMore).length;
    }
    if (distinctPairsCount == 0) distinctPairsCount = cauList.length;
    if (pairsOverLimitCount == 0) {
      pairsOverLimitCount = cauList.where((c) => c.count > 1).length;
    }

    if (topGoldPair == null && cauList.isNotEmpty) {
      topGoldPair = '${cauList.first.pair} (${cauList.first.count} cầu)';
    }

    return SoiCauResult(
      targetDate: targetDate,
      limitDays: limitDays,
      exactLimit: exactLimit,
      nhay: nhay,
      isDb: isDb,
      isLon: isLon,
      topGoldPair: topGoldPair,
      topGoldDesc: topGoldDesc,
      totalBridges: totalBridges,
      bridgesOverLimit: bridgesOverLimit,
      distinctPairsCount: distinctPairsCount,
      pairsOverLimitCount: pairsOverLimitCount,
      cauList: cauList,
      allPositions: allPositions,
      matrixConnections: matrixConnections,
      matrixDigits: matrixDigits,
      isFromWeb: true,
    );
  }

  /// Fetch bridge detail and historical road from RongBachKim
  Future<CauDetail?> fetchCauDetailFromWeb({
    required String position,
    required DateTime date,
    int limit = 5,
    int exactLimit = 0,
    int nhay = 1,
    bool isDb = false,
    bool isLon = true,
  }) async {
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final url =
        'https://rongbachkim.net/soicau.php?sendhtml&showcau&ngay=$isoDate&limit=$limit&exactlimit=$exactLimit&lon=${isLon ? 1 : 0}&db=${isDb ? 1 : 0}&vt=$position&nhay=$nhay';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data.toString();
        if (html.contains('ketquacau') || html.contains('dự đoán')) {
          return _parseCauDetailHtml(
            html: html,
            position: position,
            date: isoDate,
            limitDays: limit,
          );
        }
      }
    } catch (e) {
      debugPrint('SoiCauService: fetchCauDetailFromWeb error: $e');
    }
    return null;
  }

  /// Parse bridge detail HTML
  CauDetail _parseCauDetailHtml({
    required String html,
    required String position,
    required String date,
    required int limitDays,
  }) {
    final doc = parse(html);

    // 1. Predicted numbers
    final predictedNumbers = <String>[];
    for (var b in doc.querySelectorAll('b')) {
      final text = b.text.trim();
      if (RegExp(r'^\d{2}$').hasMatch(text)) {
        if (!predictedNumbers.contains(text)) {
          predictedNumbers.add(text);
        }
      }
    }

    // 2. Historical tables
    final historyDays = <CauHistoryDay>[];
    final tables = doc.querySelectorAll('table.ketquacau');

    for (var table in tables) {
      final header = table.querySelector('thead th')?.text.trim() ?? '';
      final char1List = <String>[];
      final hitNumbers = <String>[];

      for (var span in table.querySelectorAll('span.cau_vt1')) {
        char1List.add(span.text.trim());
      }
      for (var span in table.querySelectorAll('span.cau_lo')) {
        final hit = span.text.trim();
        if (!hitNumbers.contains(hit)) {
          hitNumbers.add(hit);
        }
      }

      final c1 = char1List.isNotEmpty ? char1List[0] : '';
      final c2 = char1List.length > 1 ? char1List[1] : '';

      final prizeStructure = <String, List<String>>{};
      for (var tr in table.querySelectorAll('tr')) {
        final gname = tr.querySelector('td.gname')?.text.trim();
        if (gname != null && gname.isNotEmpty) {
          final cells = tr.querySelectorAll('td:not(.gname)');
          prizeStructure[gname] = cells.map((c) => c.text.trim()).toList();
        }
      }

      historyDays.add(CauHistoryDay(
        drawDate: header,
        predictedPair: c1.isNotEmpty && c2.isNotEmpty ? '$c1$c2, $c2$c1' : '',
        char1: c1,
        char2: c2,
        hitNumbers: hitNumbers,
        prizeStructure: prizeStructure,
      ));
    }

    return CauDetail(
      position: position,
      date: date,
      predictedNumbers: predictedNumbers,
      limitDays: limitDays,
      historyDays: historyDays,
      rawHtml: html,
    );
  }

  /// Compute Soi Cau completely offline from SQLite history
  SoiCauResult computeFromLocal({
    required List<LotteryResult> history,
    required DateTime date,
    int limitDays = 5,
    int exactLimit = 0,
    int nhay = 1,
    bool isDb = false,
    bool isLon = true,
    String? searchNum,
  }) {
    final targetDateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (history.isEmpty) {
      return SoiCauResult.empty(
        targetDate: targetDateStr,
        limitDays: limitDays,
        exactLimit: exactLimit,
        nhay: nhay,
        isDb: isDb,
        isLon: isLon,
      );
    }

    // 1. Sort history newest first
    final sorted = List<LotteryResult>.from(history)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    // 2. Find the starting draw index D0 (the latest draw BEFORE target date, or the latest draw if target is future)
    int startIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].drawDate.compareTo(targetDateStr) < 0) {
        startIndex = i;
        break;
      }
    }

    // If all draws in history are on or after target date, use the oldest available
    if (startIndex == -1) {
      // If targetDate matches the latest draw, start from index 0
      startIndex = 0;
    }

    // Required number of draws: D0 (predicts for targetDate) + limitDays historical draws + 1 for checking exactLimit
    final neededDraws = startIndex + limitDays + 2;
    if (sorted.length < neededDraws) {
      return SoiCauResult.empty(
        targetDate: targetDateStr,
        limitDays: limitDays,
        exactLimit: exactLimit,
        nhay: nhay,
        isDb: isDb,
        isLon: isLon,
      );
    }

    // 3. Extract the 107-digit matrix for each relevant draw
    // matrixList[0] is D0 (the draw predicting targetDate)
    // matrixList[1] is D1, matrixList[2] is D2, etc.
    final matrixList = <List<String>>[];
    for (int i = 0; i <= limitDays + 1 && (startIndex + i) < sorted.length; i++) {
      matrixList.add(_extract107Digits(sorted[startIndex + i]));
    }

    final allPositions = <BridgePosition>[];
    final pairBridgeMap = <String, List<String>>{};
    final matrixConnections = <int, List<int>>{};

    // 4. Scan all candidate position pairs (i, j)
    for (int i = 0; i < 107; i++) {
      // If isLon is true, (i, j) and (j, i) are symmetrical so j starts from i + 1.
      // If isLon is false (bạch thủ), direction matters, so j can be any other index.
      final startJ = isLon ? (i + 1) : 0;
      for (int j = startJ; j < 107; j++) {
        if (i == j) continue;

        bool isValidBridge = true;

        // Check each transition: from draw (day + 1) to draw (day)
        for (int day = 0; day < limitDays; day++) {
          final prevMatrix = matrixList[day + 1];
          final char1 = prevMatrix[i];
          final char2 = prevMatrix[j];

          final num1 = '$char1$char2';
          final num2 = '$char2$char1';

          final targetDraw = sorted[startIndex + day];
          int hitCount = 0;

          if (isDb) {
            if (targetDraw.db.length >= 2) {
              final last2 = targetDraw.db.substring(targetDraw.db.length - 2);
              if (last2 == num1 || (isLon && last2 == num2)) {
                hitCount++;
              }
            }
          } else {
            for (var p in targetDraw.allNumbers) {
              if (p.length >= 2) {
                final last2 = p.substring(p.length - 2);
                if (last2 == num1 || (isLon && last2 == num2)) {
                  hitCount++;
                }
              }
            }
          }

          if (hitCount < nhay) {
            isValidBridge = false;
            break;
          }
        }

        if (!isValidBridge) continue;

        // Check if bridge is longer than limitDays (day = limitDays)
        bool isMore = false;
        if (matrixList.length > limitDays + 1 && sorted.length > startIndex + limitDays) {
          final prevMatrix = matrixList[limitDays + 1];
          final char1 = prevMatrix[i];
          final char2 = prevMatrix[j];
          final num1 = '$char1$char2';
          final num2 = '$char2$char1';

          final targetDraw = sorted[startIndex + limitDays];
          int hitCount = 0;

          if (isDb) {
            if (targetDraw.db.length >= 2) {
              final last2 = targetDraw.db.substring(targetDraw.db.length - 2);
              if (last2 == num1 || (isLon && last2 == num2)) hitCount++;
            }
          } else {
            for (var p in targetDraw.allNumbers) {
              if (p.length >= 2) {
                final last2 = p.substring(p.length - 2);
                if (last2 == num1 || (isLon && last2 == num2)) hitCount++;
              }
            }
          }
          isMore = hitCount >= nhay;
        }

        // If exactLimit == 1 (Chính xác bằng N ngày), bridge must NOT have run longer
        if (exactLimit == 1 && isMore) {
          continue;
        }

        // Prediction for targetDate comes from D0 (matrixList[0])
        final c1 = matrixList[0][i];
        final c2 = matrixList[0][j];
        final posStr = '${i}x$j';
        final pred1 = '$c1$c2';
        final pred2 = '$c2$c1';

        final pairKey = !isLon
            ? pred1
            : (pred1.compareTo(pred2) <= 0
                ? (pred1 == pred2 ? pred1 : '$pred1,$pred2')
                : '$pred2,$pred1');

        if (searchNum != null && searchNum.trim().isNotEmpty) {
          final s = searchNum.trim();
          final sParts = s.split(',').map((e) => e.trim()).toList();
          final matches = sParts.any((p) => p == pred1 || (isLon && p == pred2));
          if (!matches) continue;
        }

        allPositions.add(BridgePosition(
          position: posStr,
          number: pred1,
          vt1: i,
          vt2: j,
          isMore: isMore,
        ));

        matrixConnections.putIfAbsent(i, () => []).add(j);
        matrixConnections.putIfAbsent(j, () => []).add(i);

        pairBridgeMap.putIfAbsent(pairKey, () => []).add(posStr);
      }
    }

    final cauList = pairBridgeMap.entries.map((e) {
      return CauItem(
        pair: e.key,
        count: e.value.length,
        positions: e.value,
        isGold: false,
      );
    }).toList();

    cauList.sort((a, b) => b.count.compareTo(a.count));

    if (cauList.isNotEmpty) {
      cauList[0] = CauItem(
        pair: cauList[0].pair,
        count: cauList[0].count,
        positions: cauList[0].positions,
        isGold: true,
      );
    }

    final topGold = cauList.isNotEmpty
        ? '${cauList.first.pair} (${cauList.first.count} cầu)'
        : null;

    final bridgesOverLimit = allPositions.where((p) => p.isMore).length;

    return SoiCauResult(
      targetDate: targetDateStr,
      limitDays: limitDays,
      exactLimit: exactLimit,
      nhay: nhay,
      isDb: isDb,
      isLon: isLon,
      topGoldPair: topGold,
      topGoldDesc: topGold != null ? 'Cặp số có nhiều cầu nhất' : null,
      totalBridges: allPositions.length,
      bridgesOverLimit: bridgesOverLimit,
      distinctPairsCount: cauList.length,
      pairsOverLimitCount: cauList.where((c) => c.count > 1).length,
      cauList: cauList,
      allPositions: allPositions,
      matrixConnections: matrixConnections,
      matrixDigits: matrixList.isNotEmpty ? matrixList[0] : [],
      isFromWeb: false,
    );
  }

  /// Generate offline historical road for a bridge (when network is unavailable)
  CauDetail computeCauDetailOffline({
    required List<LotteryResult> history,
    required String position,
    required DateTime date,
    int limitDays = 5,
    bool isLon = true,
    bool isDb = false,
    int nhay = 1,
  }) {
    final parts = position.split('x');
    final vt1 = int.tryParse(parts[0]) ?? 0;
    final vt2 = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final targetDateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final sorted = List<LotteryResult>.from(history)
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    int startIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].drawDate.compareTo(targetDateStr) < 0) {
        startIndex = i;
        break;
      }
    }
    if (startIndex == -1) startIndex = 0;

    final matrixList = <List<String>>[];
    for (int i = 0; i <= limitDays && (startIndex + i) < sorted.length; i++) {
      matrixList.add(_extract107Digits(sorted[startIndex + i]));
    }

    final predictedNumbers = <String>[];
    if (matrixList.isNotEmpty) {
      final c1 = matrixList[0][vt1];
      final c2 = matrixList[0][vt2];
      predictedNumbers.add('$c1$c2');
      if (isLon && c1 != c2) {
        predictedNumbers.add('$c2$c1');
      }
    }

    final historyDays = <CauHistoryDay>[];
    for (int day = 0; day < limitDays && (startIndex + day) < sorted.length; day++) {
      if (day + 1 >= matrixList.length) break;

      final prevMatrix = matrixList[day + 1];
      final c1 = prevMatrix[vt1];
      final c2 = prevMatrix[vt2];
      final pred1 = '$c1$c2';
      final pred2 = '$c2$c1';

      final draw = sorted[startIndex + day];
      final hitNumbers = <String>[];

      if (isDb) {
        if (draw.db.length >= 2) {
          final last2 = draw.db.substring(draw.db.length - 2);
          if (last2 == pred1 || (isLon && last2 == pred2)) {
            hitNumbers.add(last2);
          }
        }
      } else {
        for (var p in draw.allNumbers) {
          if (p.length >= 2) {
            final last2 = p.substring(p.length - 2);
            if (last2 == pred1 || (isLon && last2 == pred2)) {
              if (!hitNumbers.contains(last2)) hitNumbers.add(last2);
            }
          }
        }
      }

      final prizeStructure = <String, List<String>>{
        'ĐB': [draw.db],
        'G1': [draw.g1],
        'G2': draw.g2,
        'G3': draw.g3,
        'G4': draw.g4,
        'G5': draw.g5,
        'G6': draw.g6,
        'G7': draw.g7,
      };

      historyDays.add(CauHistoryDay(
        drawDate: 'Mở thưởng ${draw.drawDate}',
        predictedPair: isLon ? '$pred1, $pred2' : pred1,
        char1: c1,
        char2: c2,
        hitNumbers: hitNumbers,
        prizeStructure: prizeStructure,
      ));
    }

    return CauDetail(
      position: position,
      date: targetDateStr,
      predictedNumbers: predictedNumbers,
      limitDays: limitDays,
      historyDays: historyDays,
    );
  }

  /// Extract 107 digits from standard XSMB prize structure
  List<String> _extract107Digits(LotteryResult result) {
    final list = <String>[];

    void addDigits(String s, int expectedLen) {
      final padded = s.padLeft(expectedLen, '0');
      for (int i = 0; i < padded.length; i++) {
        list.add(padded[i]);
      }
    }

    // ĐB (5 digits) - index 0..4
    addDigits(result.db, 5);

    // G1 (5 digits) - index 5..9
    addDigits(result.g1, 5);

    // G2 (2 x 5 = 10 digits) - index 10..19
    for (int i = 0; i < 2; i++) {
      final s = i < result.g2.length ? result.g2[i] : '00000';
      addDigits(s, 5);
    }

    // G3 (6 x 5 = 30 digits) - index 20..49
    for (int i = 0; i < 6; i++) {
      final s = i < result.g3.length ? result.g3[i] : '00000';
      addDigits(s, 5);
    }

    // G4 (4 x 4 = 16 digits) - index 50..65
    for (int i = 0; i < 4; i++) {
      final s = i < result.g4.length ? result.g4[i] : '0000';
      addDigits(s, 4);
    }

    // G5 (6 x 4 = 24 digits) - index 66..89
    for (int i = 0; i < 6; i++) {
      final s = i < result.g5.length ? result.g5[i] : '0000';
      addDigits(s, 4);
    }

    // G6 (3 x 3 = 9 digits) - index 90..98
    for (int i = 0; i < 3; i++) {
      final s = i < result.g6.length ? result.g6[i] : '000';
      addDigits(s, 3);
    }

    // G7 (4 x 2 = 8 digits) - index 99..106
    for (int i = 0; i < 4; i++) {
      final s = i < result.g7.length ? result.g7[i] : '00';
      addDigits(s, 2);
    }

    // Ensure list has exactly 107 digits
    while (list.length < 107) {
      list.add('0');
    }
    return list.take(107).toList();
  }
}
