// ignore_for_file: avoid_print
import 'dart:io'; import 'dart:convert'; void main() async { final httpClient = HttpClient(); final request = await httpClient.getUrl(Uri.parse('http://localhost:8081/xsmb/public/phan-tich')); final response = await request.close(); final body = await response.transform(utf8.decoder).join(); print(body.substring(0, 2000)); }
