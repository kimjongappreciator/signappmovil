import 'dart:convert';
import 'package:signappflutter/model/logModel.dart';
import 'package:http/http.dart' as http;

class logApi{
  //static const String logurl= 'http://192.168.1.38:5000';
  static const String logurl= 'http://181.67.73.92:5000';
  static Future<List<logmodel>> fetchLogs() async {
    const url = '$logurl/read';
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final body = response.body;
    final json = jsonDecode(body);
    final result = json['translations'] as List<dynamic>;
    final transformed = result.map((e){
      return logmodel.fromJson(e);
    }).toList();
    return transformed;
  }

  static Future<dynamic> postLog(dynamic body) async{
    final headers = {"Content-type": "application/json"};
    const url = '$logurl/write';
    final uri = Uri.parse(url);
    final json = jsonEncode(body);
    final res = await http.post(uri, headers: headers, body: json);
    return res.statusCode;
  }

  static Future<dynamic> testConnection() async{
    final headers = {"Content-type": "application/json"};
    const url = '$logurl/test';
    final uri = Uri.parse(url);
    final res = await http.get(uri, headers: headers);
    return res.statusCode;
  }

}