import 'dart:ui';

import 'package:FitnessApp/helpers/file_processor.dart';
import 'package:FitnessApp/models/chat_message.dart';
import 'package:FitnessApp/screens/thread_screen.dart';
import 'package:FitnessApp/services/chat_bot_api.dart';
import 'package:FitnessApp/services/chat_storage_service.dart';
import 'package:FitnessApp/services/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:FitnessApp/widgets/glass_container.dart';
import 'package:lottie/lottie.dart';

class Chatbootscreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const Chatbootscreen({super.key, required this.openDrawer});

  @override
  State<Chatbootscreen> createState() => _Chatbotscreenstate();
}

class _Chatbotscreenstate extends State<Chatbootscreen> {
  // bool _isThreadOpen = false;
  // String? _currentChatId;
  // String? _initialMessage;
  // final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
  }

  Widget _promptChip(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _promptContainer(List<String> prompts) {
    return SizedBox(
      width: 307, // width of one 2x2 page
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _promptChip(
                  prompts[0],
                  onTap: () => _onPromptTap(prompts[0]),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _promptChip(
                  prompts[1],
                  onTap: () => _onPromptTap(prompts[1]),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _promptChip(
                  prompts[2],
                  onTap: () => _onPromptTap(prompts[2]),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _promptChip(
                  prompts[3],
                  onTap: () => _onPromptTap(prompts[3]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPromptTap(String text) {
    setState(() {
      _controller.text = text;
    });

    // Move cursor to end
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    // Focus the search bar
    FocusScope.of(context).requestFocus(_inputFocus);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // final cardWidth = screenWidth * 0.9;
    // final orbSize = screenWidth * 0.4;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 120),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white38),
                      onPressed: widget.openDrawer,
                    ),
                    Expanded(
                      child: Center(
                        child: const Text(
                          "AI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Add empty SizedBox to balance the left icon
                    const SizedBox(width: 48), // same width as IconButton
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 160,
                width: 160,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        190,
                        182,
                        191,
                      ).withOpacity(0.6),
                      blurRadius: 70,
                      spreadRadius: 7,
                    ),
                  ],
                ),
                // child: Lottie.asset('assests/Looping_Energy_Orb.json'),
                child: Lottie.asset('assests/LowPolyjson.json'),
              ),
              SizedBox(height: 15),
              Text(
                "Hii user",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "I Analyze your recovery, sleep,stress and nutrition",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  // fontWeight: FontWeight.bold,
                ),
              ),
              // SizedBox(height: 10),
              Text(
                "Ask me anything about today's performance....",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  // fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // FakeGlassContainer(
              //   child: Container(
              //     height: 55,
              //     width: 330,
              //     child: SearchBar(
              //       controller: _controller,
              //       backgroundColor: WidgetStateProperty.all(
              //         Colors.grey.withOpacity(0.04),
              //       ),

              //       elevation: WidgetStateProperty.all(0),
              //       shadowColor: WidgetStateProperty.all(Colors.transparent),
              //       surfaceTintColor: WidgetStateProperty.all(
              //         Colors.transparent,
              //       ),
              //       padding: WidgetStateProperty.all(
              //         const EdgeInsets.symmetric(horizontal: 20),
              //       ),
              //       hintText: "Ask Something.....",
              //       leading: Icon(Icons.search, color: Colors.white54),
              //       trailing: [
              //         IconButton(
              //           onPressed: () async {
              //             if (_controller.text.trim().isEmpty) return;

              //             final userMessage = _controller.text;

              //             setState(() {
              //               _messages.add({
              //                 "role": "user",
              //                 "content": userMessage,
              //               });
              //               _isLoading = true;
              //             });

              //             _controller.clear();

              //             try {
              //               final reply = await OpenAIService.sendMessage(
              //                 _messages,
              //               );

              //               setState(() {
              //                 _messages.add({
              //                   "role": "assistant",
              //                   "content": reply,
              //                 });
              //                 _isLoading = false;
              //               });
              //             } catch (e) {
              //               setState(() {
              //                 _isLoading = false;
              //               });
              //             }
              //           },
              //           icon: Icon(Icons.mic, color: Colors.white54),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 5,
                children: [
                  _glassCard(
                    radius: BorderRadius.circular(30),
                    height: 55,
                    width: 270,
                    child: SearchBar(
                      focusNode: _inputFocus,
                      controller: _controller,
                      textStyle: WidgetStateProperty.all(
                        TextStyle(color: Colors.white),
                      ),

                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                      surfaceTintColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      hintText: "Ask Something...",
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(color: Colors.white12),
                      ),
                      leading: GestureDetector(
                        // onTap: () {
                        //   pickAndSave();
                        // },
                        onTap: () async {
                          final file = await pickAndSave();
                          if (file == null) return;
                          await FileProcessingService.processFile(file.fileId);
                          final chat = ChatStorageService.createNewChat();
                          ChatStorageService.setLastActiveChat(chat.id);
                          var content =
                              "The user send a file , with file name ${file.name}and it's summary is ${file.contentsummary}";
                          ChatStorageService.saveMessage(
                            chat.id,
                            ChatMessage(
                              role: "user",
                              type: "file",
                              fileId: file.fileId,
                              // content: file.contentsummary!+'message',
                              content: content,
                              timestamp: DateTime.now(),
                            ),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatthreadScreen(
                                chatId: chat.id,
                                fileId: file.fileId,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.add, color: Colors.white54),
                      ),
                      trailing: [
                        GestureDetector(
                          child: const Icon(Icons.send, color: Colors.white54),
                          onTap: () {
                            final text = _controller.text.trim();
                            final chat = ChatStorageService.createNewChat();
                            ChatStorageService.setLastActiveChat(chat.id);
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 250,
                                ),
                                pageBuilder: (_, __, ___) => ChatthreadScreen(
                                  chatId: chat.id,
                                  initialMessage: text.isEmpty ? null : text,
                                ),
                                transitionsBuilder: (_, animation, __, child) {
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                            // setState(() {
                            //   _isThreadOpen = true;
                            //   _currentChatId = chat.id;
                            //   _initialMessage = text.isEmpty ? null : text;
                            // });
                            _controller.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final text = _controller.text.trim();
                      final chat =
                          ChatStorageService.getLastActiveChat() ??
                          ChatStorageService.createNewChat();

                      ChatStorageService.setLastActiveChat(chat.id);

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 250),
                          pageBuilder: (_, __, ___) => ChatthreadScreen(
                            chatId: chat.id,
                            initialMessage: text.isEmpty ? null : text,
                          ),
                          transitionsBuilder: (_, animation, __, child) {
                            return SizeTransition(
                              sizeFactor: animation,
                              child: child,
                            );
                          },
                        ),
                      );

                      _controller.clear();
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _glassCard(
                radius: BorderRadius.circular(30),
                width: 330,
                // padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 15, bottom: 15, top: 2),
                      child: const Text(
                        "Suggested Prompts",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _promptContainer([
                            "Improve my sleep",
                            "Why is my stress high?",
                            "Recovery tips",
                            "Weekly summary",
                          ]),

                          SizedBox(width: 15),

                          // Future prompts page
                          _promptContainer([
                            "Nutrition advice",
                            "Hydration check",
                            "Workout load",
                            "Heart rate zones",
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _glassCard({
    required Widget child,
    double? height,
    double? width,
    BorderRadius? radius,
  }) {
    final borderRadius = radius ?? BorderRadius.circular(20);

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height, // optional ✅
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: borderRadius,
          ),
          child: content,
        ),
      ),
    );
  }
}
