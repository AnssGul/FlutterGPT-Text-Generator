import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  List<Message> msgs = [];
  bool isTyping = false;
  bool isSending = false;

  String? apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<void> sendMsg() async {
    if (isSending) return;
    isSending = true;

    String text = controller.text.trim();
    controller.clear();

    if (text.isNotEmpty) {
      setState(() {
        msgs.insert(0, Message(true, text));
        isTyping = true;
      });

      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      try {
        if (apiKey == null || apiKey!.isEmpty) {
          throw Exception("API Key is missing!");
        }

        final response = await http.post(
          Uri.parse("https://api.openai.com/v1/completions"),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {"role": "user", "content": text}
            ],
          }),
        );

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          String botReply =
              jsonResponse["choices"][0]["message"]["content"].toString();

          setState(() {
            isTyping = false;
            msgs.insert(0, Message(false, botReply.trim())); // Bot's reply
          });

          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else if (response.statusCode == 429) {
          setState(() {
            isTyping = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: Too many requests. Please wait and try again.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          setState(() {
            isTyping = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${response.statusCode} - ${response.body}"),
            ),
          );
        }
      } catch (e) {
        setState(() {
          isTyping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    isSending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Bot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: msgs.length,
              reverse: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: msgs[index].isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: msgs[index].isSender
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          msgs[index].msg,
                          style: TextStyle(
                            color: msgs[index].isSender
                                ? Colors.black
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isTyping && index == 0 && !msgs[index].isSender)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Typing...",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Enter your message",
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) => sendMsg(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMsg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isSender;
  final String msg;

  Message(this.isSender, this.msg);
}
