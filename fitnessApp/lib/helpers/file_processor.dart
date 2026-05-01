import 'dart:convert';
import 'dart:io';

import 'package:FitnessApp/models/file_model.dart';
import 'package:FitnessApp/services/chat_bot_api.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class FileProcessingService {
  //
  // static Future<void> fileToBase64(String filePath) async {
  //   // 1. Get the file object
  //   File file = File(filePath);

  //   // 2. Read file as bytes
  //   List<int> imageBytes = await file.readAsBytes();

  //   // 3. Encode bytes to base64 string
  //   var basefile = base64Encode(imageBytes);

  //   var response = await sendMessage([
  //     {
  //       "role": "system",
  //       "content": "Summarize this medical report with key findings only",
  //     },
  //     {"role": "user", "content": basefile},
  //   ]);
  //   print("BASEFILE RESPONSE: $response");
  // }

  static Future<void> processFile(String fileId) async {
    final file = Hive.box<FileModel>('files').get(fileId);
    if (file == null) return;
    try {
      final extractText = await extractPdfText(file.path);
      print("extracted text = $extractText");
      // await fileToBase64(file.path);
      final summary = await sendMessage([
        {
          "role": "system",
          "content": "Summarize this medical report with key findings only",
        },
        {"role": "user", "content": extractText},
      ]);
      file.contentsummary = summary;
      await file.save();

      print("File Content summary = ${file.contentsummary}");
    } on Exception catch (e) {
      print("File processing error: $e");
    }
  }

  static Future<String> extractPdfText(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    // print("Processing completed");
    // print("TExt $text");
    document.dispose();

    return text;
  }

  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    const String _apiKey =
        "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";
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": messages,
        "temperature": 0.7,
        // "tools": tools,
      }),
    );
    final data = jsonDecode(response.body);

    if (!data.containsKey("choices")) {
      throw Exception("OpenAI API error: ${response.body}");
    }
    print(data["choices"][0]["message"]["content"] ?? "");
    return data["choices"][0]["message"]["content"] ?? "";
  }
}
