import 'dart:io';
import 'package:FitnessApp/helpers/file_processor.dart';
import 'package:FitnessApp/models/chat_message.dart';
import 'package:FitnessApp/screens/thread_screen.dart';
import 'package:FitnessApp/services/chat_storage_service.dart';
import 'package:FitnessApp/services/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:FitnessApp/models/file_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_file/open_file.dart';

class ReportsScreen extends StatelessWidget {
  late FileModel? file;
  @override
  Widget build(BuildContext context) {
    final box = Hive.box<FileModel>('files');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        title: Text('My Files', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<FileModel> filesBox, _) {
              if (filesBox.isEmpty) {
                return Center(child: Text("No files found"));
              }

              List<FileModel> filesList = filesBox.values.toList();
              filesList.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
              return ListView.builder(
                itemCount: filesBox.length,
                itemBuilder: (context, index) {
                  final file = filesBox.getAt(index)!;

                  String formattedDate = DateFormat(
                    'dd/MM/yy',
                  ).format(file.uploadDate);
                  return ListTile(
                    leading: _buildFileIcon(file),
                    title: Text(
                      file.name,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(formattedDate),
                    onTap: () {
                      _openFile(file);
                    },
                  );
                },
              );
            },
          ),
          Positioned(
            left: 110,
            bottom: 50,
            right: 110,
            // top: 450,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: GestureDetector(
                onTap: () async {
                  file = await pickAndSave();
                  if (file != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text("Uploaded Successfully"),
                            TextButton(
                              onPressed: () {
                                FileProcessingService.processFile(file!.fileId);
                                var chat = ChatStorageService.createNewChat();
                                var content =
                                    "The user send a file , with file name ${file?.name}and it's summary is ${file?.contentsummary}";
                                ChatStorageService.saveMessage(
                                  chat.id,
                                  ChatMessage(
                                    role: "user",
                                    type: "file",
                                    fileId: file?.fileId,
                                    // content: +'message',
                                    content: content,
                                    timestamp: DateTime.now(),
                                  ),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatthreadScreen(
                                      chatId: chat.id,
                                      fileId: file?.fileId,
                                      // initialMessage:
                                      //     'Give me an insight on my health using all of my health data present',
                                    ),
                                  ),
                                );
                              },
                              child: Text("Get an insight"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.black),
                    Text(
                      'Upload Report',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Display icon based on file type
  Widget _buildFileIcon(FileModel file) {
    if (file.type == 'pdf') {
      return Icon(Icons.picture_as_pdf, color: Colors.red, size: 40);
    } else {
      return Image.file(
        File(file.path),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
  }

  // Open file using open_file package
  void _openFile(FileModel file) {
    final f = File(file.path);
    if (f.existsSync()) {
      OpenFile.open(f.path);
    } else {
      print("File Not found");
    }
  }
}
