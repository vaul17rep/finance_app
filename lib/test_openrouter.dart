import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> testOpenRouter() async {
  const apiKey = "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";

  final response = await http.post(
    Uri.parse(
      "https://openrouter.ai/api/v1/chat/completions",
    ),

    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },

    body: jsonEncode({
      "model": "openai/gpt-4o-mini",

      "messages": [
        {
          "role": "user",
          "content": "Привет"
        }
      ]
    }),
  );

  print("STATUS:");
  print(response.statusCode);

  print("BODY:");
  print(response.body);
}