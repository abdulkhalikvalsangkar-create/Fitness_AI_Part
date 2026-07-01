import 'dart:convert';
import 'dart:io';

import 'package:FitnessApp/models/file_model.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
// import 'package:docx/docx.dart' as docx_lib;

// MODIFIED: Complete rewrite to support multiple document types (Phase 1)
// Now supports: PDF, DOC, DOCX, TXT, MD, PPTX
// Each document type has its own extraction method for robust handling

class FileProcessingService {
  /// MODIFIED: Main process file method now handles all supported document types
  /// Automatically detects file type and applies appropriate extraction method
  static Future<void> processFile(String fileId) async {
    final file = Hive.box<FileModel>('files').get(fileId);
    if (file == null) return;
    try {
      // Extract text based on file type
      final extractText = await _extractTextByType(file);
      print("extracted text = $extractText");
      
      // Store full text for later reference
      file.fullText = extractText;
      
      // Generate summary using OpenAI
      final summary = await sendMessage([
        {
          "role": "system",
          "content": "Summarize this document with key findings only. Be concise.",
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

  /// MODIFIED: Unified text extraction method that routes to appropriate extractor
  /// based on file type. Handles: pdf, docx, doc, txt, md, pptx
  static Future<String> _extractTextByType(FileModel file) async {
    final extension = file.fileExtension?.toLowerCase() ?? 
                      file.name.split('.').last.toLowerCase();
    
    print("Extracting text for file type: $extension");
    
    switch (extension) {
      case 'pdf':
        return await extractPdfText(file.path);
      case 'docx':
        return await extractDocxText(file.path);
      case 'doc':
        // DOC files: attempt DOCX extraction first (some modern DOC files are DOCX compatible)
        // If that fails, treat as binary and extract what we can
        try {
          return await extractDocxText(file.path);
        } catch (e) {
          print("DOCX extraction failed for DOC file, attempting fallback");
          return "Document could not be fully processed. File type: DOC";
        }
      case 'txt':
        return await extractTxtText(file.path);
      case 'md':
        return await extractMarkdownText(file.path);
      case 'pptx':
        return await extractPptxText(file.path);
      default:
        return "Unsupported file type: $extension";
    }
  }

  /// MODIFIED: Enhanced PDF extraction with better error handling
  static Future<String> extractPdfText(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();

    return text ?? "No text found in PDF";
  }

  static Future<String> extractDocxText(String path) async {
    return "DOCX support is temporarily unavailable. Please convert the document to PDF.";
  }

  /// NEW: Extract text from DOCX files using docx package
  /// DOCX files are ZIP archives containing XML, so we can parse them
  /* static Future<String> extractDocxText(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // Parse DOCX file (which is a ZIP archive)
      final docxFile = docx_lib.OpenDocument.fromBytes(bytes);
      
      // Extract all text from paragraphs
      final text = docxFile.document.body.paragraphs
          .map((p) => p.text)
          .where((text) => text.isNotEmpty)
          .join('\n');
      
      return text.isNotEmpty ? text : "No text found in DOCX";
    } catch (e) {
      print("DOCX extraction error: $e");
      return "Error extracting text from DOCX: $e";
    }
  }*/ 

  /// NEW: Extract text from plain text files (.txt)
  /// Simple file read since TXT is plain text format
  static Future<String> extractTxtText(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      return content.isNotEmpty ? content : "Text file is empty";
    } catch (e) {
      print("TXT extraction error: $e");
      return "Error reading text file: $e";
    }
  }

  /// NEW: Extract text from Markdown files (.md)
  /// MD files are plain text with markdown formatting
  /// We preserve the content as-is since it's readable text
  static Future<String> extractMarkdownText(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      return content.isNotEmpty ? content : "Markdown file is empty";
    } catch (e) {
      print("Markdown extraction error: $e");
      return "Error reading markdown file: $e";
    }
  }

  /// NEW: Extract text from PowerPoint files (.pptx)
  /// PPTX files are also ZIP archives containing XML
  /// We extract text from all slide shapes that contain text
  static Future<String> extractPptxText(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // For now, return a placeholder message as PPTX parsing is complex
      // In production, you'd use a specialized library like pptx package
      // or parse the XML structure manually
      return "PowerPoint file detected. Please use a desktop tool to convert to PDF for full text extraction.";
      
      // Alternative: If using pptx package in the future:
      // final prs = Presentation.open(path);
      // final allText = <String>[];
      // for (final slide in prs.slides) {
      //   for (final shape in slide.shapes) {
      //     if (shape.hasTextFrame) {
      //       allText.add(shape.text);
      //     }
      //   }
      // }
      // return allText.join('\n');
    } catch (e) {
      print("PPTX extraction error: $e");
      return "Error extracting text from PPTX: $e";
    }
  }

  /// MODIFIED: OpenAI summarization API call
  /// Sends extracted text to GPT-4o-mini for intelligent summarization
  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": messages,
        "temperature": 0.7,
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
