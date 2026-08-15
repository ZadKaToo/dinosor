import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../constants/app_constants.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/typing_dot.dart';

class AIMentorChatScreen extends StatefulWidget {
  const AIMentorChatScreen({super.key});

  @override
  State<AIMentorChatScreen> createState() => _AIMentorChatScreenState();
}

class _AIMentorChatScreenState extends State<AIMentorChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
      "สวัสดีครับ ผมคือ AI Mentor ผู้ช่วยวางแผนเส้นทางอาชีพ IT ของคุณ วันนี้ต้องการปรึกษาเรื่องการเตรียมตัว ทักษะที่ต้องใช้ หรือการสัมภาษณ์งานด้านใดครับ",
      isUser: false,
    ),
  ];
  bool _isLoading = false;

  // ตรงกับ chatbot.html
  final List<String> _quickPrompts = const [
    'ไม่มีประสบการณ์ทำพอร์ตอย่างไร',
    'ไม่จบตรงสายเริ่มอย่างไร',
    'คำถามสัมภาษณ์งาน Junior',
    'ทักษะที่ตลาดต้องการสูงสุด',
    'ฐานเงินเดือนเด็กจบใหม่',
  ];

  final Map<String, String> _quickPromptFull = const {
    'ไม่มีประสบการณ์ทำพอร์ตอย่างไร':
    'ไม่มีประสบการณ์ทำงาน ควรจัดทำพอร์ตโฟลิโออย่างไรให้โดดเด่นและน่าสนใจ',
    'ไม่จบตรงสายเริ่มอย่างไร':
    'ไม่ได้เรียนจบตรงสาย IT ควรเริ่มต้นปูพื้นฐานและเลือกสายงานอย่างไร',
    'คำถามสัมภาษณ์งาน Junior':
    'ขอตัวอย่างคำถามสัมภาษณ์งานตำแหน่ง Junior พร้อมแนวทางการตอบ',
    'ทักษะที่ตลาดต้องการสูงสุด':
    'ทักษะด้านเทคนิคและทักษะเสริมที่ตลาดงาน IT กำลังต้องการมากที่สุด',
    'ฐานเงินเดือนเด็กจบใหม่':
    'โครงสร้างฐานเงินเดือนเริ่มต้นสำหรับเด็กจบใหม่ในแต่ละสายงาน IT',
  };

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http
          .post(
        Uri.parse(kMentorApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'message': text.trim()}),
      )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = (data is Map)
            ? (data['reply'] ?? data['message'] ?? data['answer'] ?? data['content'] ?? '').toString()
            : response.body;
        setState(() {
          _messages.add(ChatMessage(
            text: reply.trim().isEmpty ? 'ไม่มีข้อมูลตอบกลับจาก AI Mentor' : reply,
            isUser: false,
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'เซิร์ฟเวอร์ตอบกลับด้วยรหัส ${response.statusCode}\nลองใหม่อีกครั้งหรือตรวจสอบว่า API tunnel ยังเปิดอยู่',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text:
          'ไม่สามารถเชื่อมต่อ AI Mentor ได้\n($e)\n\nตรวจสอบว่า localtunnel/API ที่ `$kMentorApiUrl` ยังออนไลน์อยู่',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final userBubble = state.isLightTheme ? const Color(0xFF0D1B3E) : const Color(0xFF059669);
    final aiBubble = state.isLightTheme ? const Color(0xFFF2F4F6) : state.cardColor;

    return Scaffold(
      backgroundColor: state.isLightTheme ? const Color(0xFFF8F9FB) : state.bgColor,
      appBar: AppBar(
        backgroundColor: state.isLightTheme ? Colors.white : state.cardColor,
        foregroundColor: state.textPrimary,
        elevation: 0.5,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: state.accentColor,
                  radius: 18,
                  child: Icon(Icons.smart_toy, size: 18,
                      color: state.isLightTheme ? Colors.white : Colors.black),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C076),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Mentor',
                    style: GoogleFonts.prompt(
                        fontSize: 15, fontWeight: FontWeight.bold, color: state.textPrimary)),
                Text('Online',
                    style: GoogleFonts.prompt(
                        fontSize: 11, color: const Color(0xFF00C076))),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: aiBubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: state.borderColorSoft),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TypingDot(delay: 0),
                          const SizedBox(width: 4),
                          TypingDot(delay: 150),
                          const SizedBox(width: 4),
                          TypingDot(delay: 300),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: msg.isUser ? userBubble : aiBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(msg.isUser ? 16 : 4),
                        topRight: Radius.circular(msg.isUser ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      border: msg.isUser ? null : Border.all(color: state.borderColorSoft),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: GoogleFonts.prompt(
                          color: msg.isUser ? Colors.white : state.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                        strong: GoogleFonts.prompt(
                          color: msg.isUser ? Colors.white : state.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        listBullet: GoogleFonts.prompt(
                          color: msg.isUser ? Colors.white : state.textPrimary,
                          fontSize: 13,
                        ),
                        h3: GoogleFonts.prompt(
                          color: msg.isUser ? Colors.white : state.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: state.isLightTheme ? Colors.white : state.cardColor,
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final label = _quickPrompts[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_quickPromptFull[label] ?? label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: state.isLightTheme
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFF022C22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.isLightTheme
                              ? const Color(0xFF00C076)
                              : const Color(0xFF065F46),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: GoogleFonts.prompt(
                          color: state.isLightTheme
                              ? const Color(0xFF008751)
                              : const Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: state.isLightTheme ? Colors.white : state.cardColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isLightTheme
                    ? const Color(0xFFF2F4F6)
                    : state.cardAltColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความที่นี่...',
                        hintStyle: GoogleFonts.prompt(color: state.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  Material(
                    color: state.isLightTheme
                        ? const Color(0xFF0D1B3E)
                        : state.accentColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isLoading ? null : () => _sendMessage(_controller.text),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
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
