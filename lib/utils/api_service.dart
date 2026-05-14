import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static Future<Map<String, dynamic>> scanAmulet(String base64Image) async {
    final apiKey = dotenv.env['ROBOFLOW_API_KEY'];
    final url = Uri.parse(
      'https://serverless.roboflow.com/infer/workflows/s-workspace-bkqdt/thai-amulet-scanner-1778311181400'
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'api_key': apiKey,
        'inputs': {
          'image': {'type': 'base64', 'value': base64Image}
        }
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
