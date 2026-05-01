import 'dart:convert';
import 'package:FitnessApp/helpers/file_picker_util.dart';
import 'package:FitnessApp/services/firebase_service.dart';
import 'package:FitnessApp/services/firestore_service.dart';
import 'package:FitnessApp/services/healthconnect.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class OpenAIService {
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? "";

  static final tools = [
    {
      "type": "function",
      "function": {
        "name": "get_step_data",
        "description":
            "Get user's daily step count over a number of days. Returns total steps and per-day breakdown.",
        "parameters": {
          "type": "object",
          "properties": {
            "days": {
              "type": "number",
              "description": "Number of past days to analyze (e.g., 7, 14, 30)",
            },
          },
          "required": ["days"],
        },
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_nutrition_data",
        "description":
            "Get user's nutrition/food/diet intake over a number of days. Includes calories, macros, and food entries if available.",
        "parameters": {
          "type": "object",
          "properties": {
            "days": {
              "type": "number",
              "description": "Number of past days to analyze",
            },
          },
          "required": ["days"],
        },
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_user_profile",
        "description":
            "Fetch static user profile information stored in the app, including name, age, gender, height, and current profile weight. Use this for personal details, BMI calculations, or profile context. Not for weight trends or Health Connect history.",
        "parameters": {"type": "object", "properties": {}},
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_user_profile",
        "description":
            "Fetch static user profile information stored in the app, including name, age, gender, height, and current profile weight. Use this for personal details, BMI calculations, or profile context. Not for weight trends or Health Connect history.",
        "parameters": {"type": "object", "properties": {}},
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_saved_files",
        "description":
            "Fetch user's saved files with optional filters like search query and number of past days to search. Example: days=1 means last 24 hours, days=7 means last 7 days.",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "Search term like 'blood', 'glucose'",
            },
            "days": {
              "type": "integer",
              "description":
                  "Number of past days to look back. Example: 1 for last 24 hours, 7 for last week, 30 for last month.",
            },
          },
        },
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_exercise_sessions",
        "description": "Get user's exercise sessions.",
        "parameters": {
          "type": "object",
          "properties": {
            "days": {
              "type": "number",
              "description": "Number of past days to analyze",
            },
          },
          "required": ["days"],
        },
      },
    },
  ];

  // static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
  //   final workingMessages = List<Map<String, dynamic>>.from(messages);
  //   final response = await http.post(
  //     Uri.parse("https://api.openai.com/v1/chat/completions"),
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $_apiKey",
  //     },
  //     body: jsonEncode({
  //       "model": "gpt-4o-mini",
  //       "messages": workingMessages,
  //       "temperature": 0.7,
  //       "tools": tools,
  //     }),
  //   );
  //   print("TEST API FIRST RESPONSE ${response.body}");
  //   final data = jsonDecode(response.body);

  //   if (!data.containsKey("choices")) {
  //     print("OPENAI ERROR RESPONSE:");
  //     print(data);
  //     throw Exception("OpenAI API error");
  //   }

  //   final message = data["choices"][0]["message"];

  //   /// If AI wants to call a tool
  //   if (message["tool_calls"] != null) {
  //     final toolCall = message["tool_calls"][0];
  //     final functionName = toolCall["function"]["name"];
  //     final arguments = jsonDecode(toolCall["function"]["arguments"]);

  //     Map<String, dynamic> result;

  //     /// TOOL ROUTER
  //     switch (functionName) {
  //       case "get_step_data":
  //         result = await HealthService.getStepsData(arguments["days"]);
  //         print("TEST Step data ${result}");
  //         break;
  //       case "get_nutrition_data":
  //         result = await HealthService.getNutritionData(arguments["days"]);
  //         print("TEST Nutriton data ${result}");
  //         break;
  //       case "get_body_metrics":
  //         result = await HealthService.getBodyWeight(arguments["days"]);
  //         print("TEST Nutriton data ${result}");
  //         break;
  //       default:
  //         result = {"error": "Unknown function"};
  //     }

  //     /// Add AI message
  //     workingMessages.add(message);

  //     /// Add tool result
  //     workingMessages.add({
  //       "role": "tool",
  //       "tool_call_id": toolCall["id"],
  //       "content": jsonEncode(result),
  //     });

  //     /// Second AI call with tool data
  //     final secondResponse = await http.post(
  //       Uri.parse("https://api.openai.com/v1/chat/completions"),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $_apiKey",
  //       },
  //       body: jsonEncode({"model": "gpt-4o-mini", "messages": workingMessages}),
  //     );

  //     final secondData = jsonDecode(secondResponse.body);

  //     return secondData["choices"][0]["message"]["content"];
  //   }

  //   /// Normal AI response
  //   return message["content"];
  // }
  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    final workingMessages = List<Map<String, dynamic>>.from(messages);
    // workingMessages.any((message) => message['filetype'] == 'file');
    (workingMessages.isNotEmpty && workingMessages.last['type'] == 'file');
    //  Remove invalid messages
    // final cleanedMessages = workingMessages
    //     .where((m) => m["content"] != null && m["content"] != "")
    //     .toList();

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": workingMessages,
        "temperature": 0.7,
        "tools": tools,
      }),
    );

    final data = jsonDecode(response.body);

    if (!data.containsKey("choices")) {
      throw Exception("OpenAI API error");
    }

    final message = data["choices"][0]["message"];
    print(message);

    /// TOOL CALL
    if (message["tool_calls"] != null) {
      final toolCall = message["tool_calls"][0];
      final functionName = toolCall["function"]["name"];
      final arguments = jsonDecode(toolCall["function"]["arguments"]);

      Map<String, dynamic> result;

      switch (functionName) {
        case "get_step_data":
          result = await HealthService.getStepsData(arguments["days"]);
          break;
        case "get_nutrition_data":
          result = await HealthService.getNutritionData(arguments["days"]);
          break;
        case "get_body_metrics":
          result = await HealthService.getBodyWeight(arguments["days"]);
          break;
        // case "get_user_height":
        // result = await HealthService.getBodyHeight(arguments["days"]);
        // break;
        case "get_saved_files":
          result = await FilePickerUtil.getSavedFiles(
            arguments["query"],
            arguments["days"],
          );
          break;
        case "get_exercise_sessions":
          final sessions = await StorageService.instance.getSessions();

          final int days = (arguments["days"] ?? 7) as int;

          final cutoff = DateTime.now().subtract(Duration(days: days));

          final filtered = sessions.where((s) {
            return s.date.isAfter(cutoff);
          }).toList();

          result = {
            "sessions": filtered.map((s) => s.toJson()).toList(),
            "count": filtered.length,
            "days": days,
          };
          break;
        case "get_user_profile":
          final user = await StorageService.instance.getUserProfile();

          result = user?.toJson() ?? {"error": "User profile not found"};
          // result = await StorageService.instance.getUserProfile();
          break;
        default:
          result = {"error": "Unknown function"};
      }
      print(result);
      workingMessages.add(message);

      workingMessages.add({
        "role": "tool",
        "tool_call_id": toolCall["id"],
        "content": jsonEncode(result),
      });

      final secondResponse = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": workingMessages,
          "tools": tools,
        }),
      );

      final secondData = jsonDecode(secondResponse.body);

      return secondData["choices"][0]["message"]["content"];
    }

    return message["content"];
  }
}
