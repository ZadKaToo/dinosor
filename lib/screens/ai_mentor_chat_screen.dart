import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/ai_mentor_service.dart';
import '../services/persistence_service.dart';
import '../widgets/google_fonts_shim.dart';
import 'login_screen.dart';

// สี fix ตามดีไซน์ต้นฉบับ (HTML/Tailwind) — ไม่ผูกกับธีม light/dark ของแอปหลัก
class _MentorColors {
  static const primary = Color(0xFF0D1B3E);
  static const green = Color(0xFF00C076);
  static const greenText = Color(0xFF008751);
  static const greenBg = Color(0xFFF0FDF4);
  static const background = Color(0xFFF8F9FB);
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainerLowest = Colors.white;
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF45464E);
}

const String _avatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCTwR-ld26Szf1gyYX2otWHXDwFHmsE8-f9wu2Ob5lCAhe189W348v2IkFsdtnYAWfHwZ7uvi5hSvhh4aGP0p4Ug17h_lbdhA-yRJhR9oGt8K3vL_AgfzX41QihGRm--5vxfvh2Rg-gpoF7ZJFpvy82iqwifWIhVT56AXr0jbQnf7nXQi7yq2UTXRALyVm-hTDBsyxFJTifULVY26vXSkcm4xxh0Ith76GWLZnscua1uAOLkc01QIWl';

const List<Map<String, String>> _quickPrompts = [
  {
    'label': 'ไม่มีประสบการณ์ทำพอร์ตอย่างไร',
    'prompt': 'ไม่มีประสบการณ์ทำงาน ควรจัดทำพอร์ตโฟลิโออย่างไรให้โดดเด่นและน่าสนใจ',
  },
  {
    'label': 'ไม่จบตรงสายเริ่มอย่างไร',
    'prompt': 'ไม่ได้เรียนจบตรงสาย IT ควรเริ่มต้นปูพื้นฐานและเลือกสายงานอย่างไร',
  },
  {
    'label': 'คำถามสัมภาษณ์งาน Junior',
    'prompt': 'ขอตัวอย่างคำถามสัมภาษณ์งานตำแหน่ง Junior พร้อมแนวทางการตอบ',
  },
  {
    'label': 'ทักษะที่ตลาดต้องการสูงสุด',
    'prompt': 'ทักษะด้านเทคนิคและทักษะเสริมที่ตลาดงาน IT กำลังต้องการมากที่สุด',
  },
  {
    'label': 'ฐานเงินเดือนเด็กจบใหม่',
    'prompt': 'โครงสร้างฐานเงินเดือนเริ่มต้นสำหรับเด็กจบใหม่ในแต่ละสายงาน IT',
  },
];

const String _careerAnalysisPrompt =
    'ช่วยวิเคราะห์ประวัติการพูดคุยและคำถามทั้งหมดที่ผ่านมาของฉัน แล้วสรุปออกมาเป็น 3 สายงาน IT '
    'ที่เหมาะสมกับฉันมากที่สุด พร้อมเปอร์เซ็นต์ความเหมาะสม และเหตุผลสั้นๆ ชัดเจน';

class AIMentorChatScreen extends StatefulWidget {
  const AIMentorChatScreen({super.key});

  @override
  State<AIMentorChatScreen> createState() => _AIMentorChatScreenState();
}

class _AIMentorChatScreenState extends State<AIMentorChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  static const String _greeting =
      'สวัสดีครับ ผมคือ AI Mentor ผู้ช่วยวางแผนเส้นทางอาชีพ IT ของคุณ '
      'วันนี้ต้องการปรึกษาเรื่องการเตรียมตัว ทักษะที่ต้องใช้ หรือการสัมภาษณ์งานด้านใดครับ '
      '(เมื่อคุยไประยะหนึ่งสามารถกดปุ่ม "วิเคราะห์ Top 3" ด้านบนได้เลยครับ)';

  @override
  void initState() {
    super.initState();
    // 🔒 กันไว้อีกชั้น: ถ้าไม่มี session ของ Supabase Auth เลย ห้ามเข้าหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Supabase.instance.client.auth.currentUser == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _loadChatHistory();
      }
    });
  }

  /// โหลดประวัติแชทจาก Supabase มาแสดงต่อ
  Future<void> _loadChatHistory() async {
    final rows = await PersistenceService.loadChatHistory(limit: 40);
    if (!mounted || rows.isEmpty) return;
    setState(() {
      for (final row in rows) {
        final userMsg = (row['user_message'] as String?)?.trim() ?? '';
        final botMsg = (row['bot_reply'] as String?)?.trim() ?? '';
        if (userMsg.isNotEmpty) {
          _messages.add(ChatMessage(text: userMsg, isUser: true));
        }
        if (botMsg.isNotEmpty) {
          _messages.add(ChatMessage(text: botMsg, isUser: false));
        }
      }
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final message = (presetText ?? _inputController.text).trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _inputController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiMentorService.sendMessage(message);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isSending = false;
      });
      // บันทึกลง Supabase (ไม่บล็อก UI)
      PersistenceService.saveChatTurn(userMessage: message, botReply: reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้',
          isUser: false,
          isError: true,
        ));
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _requestCareerAnalysis() {
    _sendMessage(_careerAnalysisPrompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MentorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildChatArea()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _MentorColors.surfaceContainerLowest,
      child: Row(
        children: [
          Stack(
            children: [
              ClipOval(
                child: Image.network(
                  _avatarUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    color: _MentorColors.primary,
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _MentorColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _MentorColors.surfaceContainerLowest, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Career Mentor',
                  style: GoogleFonts.prompt(
                    color: _MentorColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: _MentorColors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.prompt(
                        color: _MentorColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isSending ? null : _requestCareerAnalysis,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _MentorColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'วิเคราะห์ Top 3',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildChatArea() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _MentorColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'วันนี้',
              style: GoogleFonts.prompt(color: _MentorColors.onSurfaceVariant, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAiBubble(_greeting),
        for (final msg in _messages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: msg.isUser
                ? _buildUserBubble(msg.text)
                : msg.isError
                    ? _buildErrorBubble(msg.text)
                    : _buildAiBubble(msg.text),
          ),
        if (_isSending)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _TypingBubble(),
          ),
      ],
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _MentorColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Text(
          text,
          style: GoogleFonts.prompt(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.network(
              _avatarUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                color: _MentorColors.primary,
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _MentorColors.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: MarkdownBody(
                data: text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.prompt(color: _MentorColors.onSurface, fontSize: 14, height: 1.5),
                  h3: GoogleFonts.prompt(color: _MentorColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                  strong: GoogleFonts.prompt(color: _MentorColors.primary, fontWeight: FontWeight.w600),
                  listBullet: GoogleFonts.prompt(color: _MentorColors.onSurface, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.prompt(color: Colors.red.shade700, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _MentorColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: _MentorColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _quickPrompts[index];
                return GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(item['prompt']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _MentorColors.greenBg,
                      border: Border.all(color: _MentorColors.green),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['label']!,
                      style: GoogleFonts.prompt(
                        color: _MentorColors.greenText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _MentorColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: GoogleFonts.prompt(color: _MentorColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความที่นี่...',
                      hintStyle: GoogleFonts.prompt(color: _MentorColors.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _MentorColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.network(
              _avatarUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                color: _MentorColors.primary,
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _MentorColors.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = (_controller.value + (i * 0.2)) % 1.0;
                    final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _MentorColors.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
