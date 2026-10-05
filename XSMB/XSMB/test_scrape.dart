import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

void main() async {
  final dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    },
  ));
  
  try {
    final response = await dio.get('https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac.html');
    final document = parse(response.data);
    final elements = document.getElementsByClassName('giaidb');
    if (elements.isEmpty) {
      print('giaidb not found');
    } else {
      print('giaidb found: ' + elements.first.text);
    }
  } catch (e) {
    print('Error: $e');
  }
}
