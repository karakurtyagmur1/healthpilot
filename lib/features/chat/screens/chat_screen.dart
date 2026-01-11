import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:healthpilot/services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String selectedDateKey; // yyyy-MM-dd
  final Map<String, double> targets; // kcal, protein, carb, fat

  const ChatScreen({
    super.key,
    required this.userId,
    required this.selectedDateKey,
    required this.targets,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fs = FirestoreService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  // ✅ Backend endpoint
  // - Chrome/macOS: localhost genelde OK
  // - Android emülatör: http://10.0.2.2:3000/chat
  // - iOS simülatör: localhost genelde OK
  final String _endpoint = 'http://localhost:3000/chat';

  @override
  void initState() {
    super.initState();

    // İlk mesaj (isteğe bağlı)
    _messages.add(const _ChatMessage(
      text:
          'Merhaba! Bugünkü beslenmeni birlikte yönetelim. Ne sormak istersin?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, double>> _computeTotalsForSelectedDate() async {
    final items = await _fs.fetchAllFoodsByDate(
      userId: widget.userId,
      dateKey: widget.selectedDateKey,
    );

    double kcal = 0, p = 0, c = 0, f = 0;

    for (final d in items) {
      kcal += (d['kcal'] ?? 0).toDouble();
      p += (d['protein'] ?? 0).toDouble();
      c += (d['carb'] ?? 0).toDouble();
      f += (d['fat'] ?? 0).toDouble();
    }

    return {'kcal': kcal, 'protein': p, 'carb': c, 'fat': f};
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final totals = await _computeTotalsForSelectedDate();

      final targetKcal = (widget.targets['kcal'] ?? 0).toDouble();
      final targetP = (widget.targets['protein'] ?? 0).toDouble();
      final targetC = (widget.targets['carb'] ?? 0).toDouble();
      final targetF = (widget.targets['fat'] ?? 0).toDouble();

      final remainingKcal =
          (targetKcal - totals['kcal']!).clamp(0, 999999).toDouble();
      final remainingP = (targetP - totals['protein']!).toDouble();
      final remainingC = (targetC - totals['carb']!).toDouble();
      final remainingF = (targetF - totals['fat']!).toDouble();

      final payload = {
        'message': text,
        'context': {
          'dateKey': widget.selectedDateKey,
          'targets': {
            'kcal': targetKcal,
            'protein': targetP,
            'carb': targetC,
            'fat': targetF,
          },
          'totals': {
            'kcal': totals['kcal'],
            'protein': totals['protein'],
            'carb': totals['carb'],
            'fat': totals['fat'],
          },
          'remaining': {
            'kcal': remainingKcal,
            'protein': remainingP,
            'carb': remainingC,
            'fat': remainingF,
          }
        }
      };

      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = (data['reply'] ?? 'Yanıt alınamadı.').toString();

        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
      } else {
        setState(() {
          _messages.add(const _ChatMessage(
            text: 'Sunucudan yanıt alınamadı. (HTTP hata)',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Hata: $e',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _sendQuick(String q) {
    _controller.text = q;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthPilot Asistan'),
      ),
      body: Column(
        children: [
          // ✅ Hazır sorular (chip)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickChip(
                  text: 'Bugün kaç kcal hakkım kaldı?',
                  onTap: () => _sendQuick('Bugün kaç kcal hakkım kaldı?'),
                ),
                _QuickChip(
                  text: 'Proteinim eksik mi?',
                  onTap: () => _sendQuick('Proteinim eksik mi?'),
                ),
                _QuickChip(
                  text: 'Bugün ne yesem?',
                  onTap: () =>
                      _sendQuick('Bugün kalan makrolarıma göre ne yesem?'),
                ),
                _QuickChip(
                  text: 'Özet çıkar',
                  onTap: () => _sendQuick('Bugünün kısa bir özetini çıkar.'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ✅ Mesaj listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.isUser;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? cs.onPrimaryContainer : cs.onSurface,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ Input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'HealthPilot’a sor...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _send,
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

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
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
