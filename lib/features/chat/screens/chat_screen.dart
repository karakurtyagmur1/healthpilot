import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  // Şu anda backend’in senin Mac’inde çalışıyor
  // Eğer Vercel’e yüklersek bu adres değişecek
  final String _endpoint = 'http://localhost:3000/chat';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // önce kullanıcı mesajını listeye ekle
    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true),
      );
      _isSending = true;
    });
    _controller.clear();

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['reply'] ?? 'Yanıt alınamadı.';

        setState(() {
          _messages.add(
            _ChatMessage(text: reply, isUser: false),
          );
        });
      } else {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text: 'Sunucudan yanıt alınamadı.',
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Hata: $e',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthPilot Asistan')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? Colors.greenAccent.shade100
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'HealthPilot’a sor...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const CircularProgressIndicator()
                      : IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}
