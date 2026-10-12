import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String apiKey =
      "AQ.Ab8RN6JwIG59D0uFLwEu1YrDp1BWJCdC_zHQeXx_XsXiJaU67Q";

  Future<String> sendMessage(String message, String currentLangCode) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
    );

    String systemPrompt;

    if (currentLangCode == 'ur') {
      systemPrompt = """
You are a professional Wheat Disease Expert.

The user is from Pakistan.

Always reply ONLY in Urdu using the Urdu script.

Do NOT use Roman Urdu.

Give clear, accurate and concise answers about wheat diseases, fertilizers, pests and farming.
""";
    } else if (currentLangCode == 'pa') {
      systemPrompt = """
You are a professional Wheat Disease Expert.

The user is from Pakistan.

IMPORTANT INSTRUCTIONS:

• ALWAYS reply ONLY in Punjabi.
• ALWAYS write Punjabi in SHAHMUKHI (Perso-Arabic) script.
• NEVER use Gurmukhi (Indian Punjabi) script.
• NEVER reply in Hindi.
• Do NOT switch to Urdu except for technical agricultural words when absolutely necessary.
• Use natural Pakistani Punjabi.

Example style:

تہاڈے گندم دے پتے اُتے زنگ دی بیماری دے آثار نظر آ رہے نیں۔ ایس لئی مناسب فنجی سائیڈ دا استعمال کرو تے متاثرہ پتے چیک کردے رہو۔
""";
    } else {
      systemPrompt = """
You are a professional Wheat Disease Expert.

Reply only in English.

Give accurate, concise and practical advice about wheat diseases, fertilizers, irrigation, insects and crop management.
""";
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "$systemPrompt\n\nUser Question: $message"
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.6,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 4096
          }
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final parts = data["candidates"][0]["content"]["parts"];

        String answer = "";

        for (final part in parts) {
          answer += part["text"] ?? "";
        }

        return answer;
      } else {
        return "Error ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Connection Error:\n$e";
    }
  }
}