import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('DeepSeek Reasoner Test Script');
  print('-----------------------------');

  stdout.write('Please enter your DeepSeek API Key: ');
  final apiKey = stdin.readLineSync()?.trim();

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: API Key is required.');
    return;
  }

  final url = Uri.parse('https://api.deepseek.com/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  final body = {
    'model': 'deepseek-reasoner',
    'messages': [
      {'role': 'user', 'content': 'Hello!'},
    ],
    'stream': false,
  };

  print('\nSending request to $url...');
  print('Body: ${jsonEncode(body)}');

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    print('\nResponse Status: ${response.statusCode}');
    print('Response Body:');
    print(utf8.decode(response.bodyBytes));
  } catch (e) {
    print('\nError: $e');
  }

  print('\nPress Enter to exit...');
  stdin.readLineSync();
}
