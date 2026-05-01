import 'dart:ui';

import 'package:FitnessApp/models/chat_message.dart';
import 'package:FitnessApp/models/file_model.dart';
import 'package:FitnessApp/services/chat_bot_api.dart';
import 'package:FitnessApp/services/chat_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';

class ChatthreadScreen extends StatefulWidget {
  final String chatId;
  final String? initialMessage;
  final String? fileId;

  const ChatthreadScreen({
    super.key,
    required this.chatId,
    this.initialMessage,
    this.fileId,
  });

  @override
  State<ChatthreadScreen> createState() => _ChatThreadScreenstate();
}

class _ChatThreadScreenstate extends State<ChatthreadScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _hideOrb = false;

  @override
  void initState() {
    super.initState();
    final chat = ChatStorageService.getChat(widget.chatId);

    if (chat != null) {
      _messages = chat.messages.map<Map<String, dynamic>>((m) {
        return {
          "role": m.role,
          "content": m.content,
          "type": m.type,
          "fileId": m.fileId,
        };
      }).toList();
      _hideOrb = true;
    }
    print(widget.chatId);
    print(_messages.length);
    // _sendMessage("Explain");
    if (widget.initialMessage != null) {
      // _messages.add({"role": "user", "content": widget.initialMessage!});

      Future.microtask(() => _sendMessage(widget.initialMessage));
    }
    if (widget.fileId != null) {
      Future.microtask(
        () =>
            _sendMessage("Give me a summary of this file and provide insight"),
      );
    }
    // _sendMessage("Read the summary and explain");
  }

  // void _sendFileMessage(String path, String type) {
  //   ChatStorageService.saveMessage(
  //     widget.chatId,
  //     ChatMessage(role: "user", filepath: path, fileType: type),
  //   );

  //   setState(() {
  //     _messages.add({"role": "user", "filePath": path, "fileType": type});
  //   });
  // }

  // Limiting the Messages sent to AI for context
  List<Map<String, dynamic>> getContext() {
    const limit = 12; // Total of 12(6 from each side)

    return _messages.length <= limit
        ? _messages
        : _messages.sublist(_messages.length - limit);
  }

  // Future<void> _sendMessage([String? message]) async {
  //   final userMessage = message ?? _controller.text.trim();
  //   if (userMessage.isEmpty || _isLoading) return;

  //   // final userMessage = _controller.text;
  //   ChatStorageService.saveMessage(
  //     widget.chatId,
  //     ChatMessage(
  //       role: "user",
  //       content: userMessage,
  //       type: "text",
  //       timestamp: DateTime.now(),
  //     ),
  //   );
  //   setState(() {
  //     _messages.add({"role": "user", "content": userMessage});
  //     _isLoading = true;
  //   });

  //   _controller.clear();

  //   try {
  //     print(widget.chatId);
  //     print("SENDING MESSAGES:");
  //     for (var m in _messages) {
  //       print("${m['role']}: ${m['content']}");
  //     }
  //     final chat = ChatStorageService.getChat(widget.chatId);

  //     String? fileId;

  //     for (var m in chat!.messages.reversed) {
  //       if (m.fileId != null) {
  //         fileId = m.fileId;
  //         break;
  //       }
  //     }

  //     String finalMessage = userMessage;

  //     if (fileId != null) {
  //       final file = Hive.box<FileModel>('files').get(fileId);

  //       if (file?.contentsummary != null) {
  //         finalMessage =
  //             "Context:\n${file!.contentsummary}\n\nQuestion:\n$userMessage";
  //       }
  //     }

  //     final reply = await OpenAIService.sendMessage([
  //       {
  //         "role": "system",
  //         "content": "Answer only using the provided context if available.",
  //       },
  //       {
  //         "role": "user",
  //         "content":
  //             "IF you don't see anything just say I didn't get anything  $finalMessage",
  //       },
  //     ]);
  //     print("AI REPLY: $reply");

  //     ChatStorageService.saveMessage(
  //       widget.chatId,
  //       ChatMessage(
  //         role: "assistant",
  //         content: reply,
  //         type: "text",
  //         timestamp: DateTime.now(),
  //       ),
  //     );

  //     setState(() {
  //       _messages.add({"role": "assistant", "content": reply, "type": "text"});
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     print("ERROR: $e");
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }
  Future<void> _sendMessage([String? message]) async {
    final userMessage = message ?? _controller.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    // final userMessage = _controller.text;
    ChatStorageService.saveMessage(
      widget.chatId,
      ChatMessage(
        role: "user",
        content: userMessage,
        type: "text",
        timestamp: DateTime.now(),
      ),
    );
    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _isLoading = true;
      _hideOrb = true;
    });

    _controller.clear();

    try {
      print(widget.chatId);
      print("SENDING MESSAGES:");
      for (var m in _messages) {
        print("${m['role']}: ${m['content']}");
      }
      // final chat = ChatStorageService.getChat(widget.chatId);

      // String? fileId;

      // for (var m in chat!.messages.reversed) {
      //   if (m.fileId != null) {
      //     fileId = m.fileId;
      //     break;
      //   }
      // }

      // String finalMessage = userMessage;

      // if (fileId != null) {
      //   final file = Hive.box<FileModel>('files').get(fileId);

      //   if (file?.contentsummary != null) {
      //     finalMessage =
      //         "Context:\n${file!.contentsummary}\n\nQuestion:\n$userMessage";
      //   }
      // }

      final reply = await OpenAIService.sendMessage(
        getContext(),
        // {
        //   "role": "system",
        //   "content": "Answer only using the provided context if available.",
        // },
        // {
        //   "role": "user",
        //   "content":
        //       "IF you don't see anything just say I didn't get anything  $finalMessage",
        // },
      );
      print("AI REPLY: $reply");

      ChatStorageService.saveMessage(
        widget.chatId,
        ChatMessage(
          role: "assistant",
          content: reply,
          type: "text",
          timestamp: DateTime.now(),
        ),
      );

      setState(() {
        _messages.add({"role": "assistant", "content": reply, "type": "text"});
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg["role"] == "user";
    if (msg["type"] == "file") {
      final file = Hive.box<FileModel>('files').get(msg["fileId"]);

      if (file == null) return SizedBox();
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.68,
          ),
          child: GestureDetector(
            onTap: () {
              OpenFile.open(file.path);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF7A2BFF)
                    : const Color(0xFF9B5CFF).withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    file.type == "pdf" ? Icons.picture_as_pdf : Icons.image,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      // file.path.split("/").last,
                      file.name,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.68,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFF7A2BFF)
                : const Color(0xFF9B5CFF).withOpacity(0.35),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
          ),
          child: Text(
            msg["content"],
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.02),
              borderRadius: BorderRadius.circular(30),
            ),
            child: SearchBar(
              // focusNode: _inputFocus,
              controller: _controller,
              textStyle: WidgetStateProperty.all(
                TextStyle(color: Colors.white),
              ),

              backgroundColor: WidgetStateProperty.all(
                Colors.grey.withOpacity(0.04),
              ),
              elevation: WidgetStateProperty.all(0),
              hintText: "Ask Something...",
              hintStyle: WidgetStateProperty.all(
                TextStyle(color: Colors.white12),
              ),
              leading: const Icon(Icons.search, color: Colors.white54),
              trailing: [
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white54),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        // elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          /// BACKGROUND
          // Container(
          //   decoration: const BoxDecoration(
          //     gradient: RadialGradient(
          //       center: Alignment.topCenter,
          //       radius: 1.2,
          //       colors: [Color(0xFF3A2C5A), Color(0xFF0B0F1A)],
          //       stops: [0.0, 0.8],
          //     ),
          //   ),
          // ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// TITLE
                const Text(
                  "AI",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),

                const SizedBox(height: 30),

                /// AI ORB
                /// GREETING with animation
                AnimatedSlide(
                  duration: const Duration(milliseconds: 600),
                  offset: _hideOrb ? const Offset(0, -1) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _hideOrb ? 0 : 1,

                    child: Column(
                      children: [
                        Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withOpacity(0.6),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          // child: Lottie.asset('assests/Looping_Energy_Orb.json'),
                        ),

                        const SizedBox(height: 10),

                        /// GREETING
                        const Text(
                          "Hi Anna 👋",
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                /// CHAT LIST
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }

                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),

                /// INPUT BAR
                Container(
                  // height: 200,
                  child: _inputBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
