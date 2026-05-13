import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

const _starters = [
  (icon: Icons.pie_chart_outline, text: 'Bu ay nereye harcadım?'),
  (icon: Icons.flag_outlined, text: 'Hedefe ne kadar atayabilirim?'),
  (icon: Icons.warning_amber_outlined, text: 'Anomalileri göster'),
  (icon: Icons.account_balance_wallet_outlined, text: 'Bütçe öner'),
];

class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime at;
  const _Msg({required this.role, required this.content, required this.at});
}

class AgentChatPage extends StatefulWidget {
  const AgentChatPage({super.key});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _sessionId = const Uuid().v4();
  final List<_Msg> _messages = [];
  bool _thinking = false;
  bool _showHistory = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', content: text, at: DateTime.now()));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.agentSend,
        data: {'message': text, 'session_id': _sessionId},
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      final reply =
          (res.data as Map<String, dynamic>)['reply'] as String? ??
              'Yanıt alınamadı.';
      if (mounted) {
        setState(() {
          _messages.add(
              _Msg(role: 'assistant', content: reply, at: DateTime.now()));
          _thinking = false;
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error'] ?? 'Ajan yanıt veremedi.';
      setState(() {
        _messages.add(_Msg(
            role: 'assistant', content: '⚠ $msg', at: DateTime.now()));
        _thinking = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  onHistory: () => setState(() => _showHistory = true),
                  onNewChat: () => setState(() {
                    _messages.clear();
                    _thinking = false;
                  }),
                ),
                Expanded(
                  child: _messages.isEmpty && !_thinking
                      ? _EmptyChat(onPick: _send)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount:
                              _messages.length + (_thinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _messages.length) {
                              return const _TypingIndicator();
                            }
                            return _MessageBubble(msg: _messages[i]);
                          },
                        ),
                ),
                _InputArea(
                  controller: _inputCtrl,
                  enabled: !_thinking,
                  onSend: _send,
                  lastSuggestions: _messages.isNotEmpty &&
                          _messages.last.role == 'assistant'
                      ? null
                      : null,
                ),
              ],
            ),
            if (_showHistory)
              _HistorySheet(onClose: () => setState(() => _showHistory = false)),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onNewChat;
  const _Header({required this.onHistory, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bg0,
        border: Border(bottom: BorderSide(color: AppColors.border1Dark)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFF0A7DA8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.accentDim,
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                size: 20, color: AppColors.accentText),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paranette AI',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1Dark)),
                SizedBox(height: 2),
                Row(
                  children: [
                    _OnlineDot(),
                    SizedBox(width: 4),
                    Text('Çevrimiçi',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
          _IconBtn(icon: Icons.list, onTap: onHistory),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.add, onTap: onNewChat),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.accent),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg2,
          border: Border.all(color: AppColors.border1Dark),
        ),
        child: Icon(icon, size: 16, color: AppColors.text2Dark),
      ),
    );
  }
}

// ── Empty chat ───────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final void Function(String) onPick;
  const _EmptyChat({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
      children: [
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.accent, Color(0xFF0A7DA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 32, color: AppColors.accentText),
            ),
            const SizedBox(height: 16),
            Text('Merhaba',
                style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.text1Dark, letterSpacing: -0.02 * 22)),
            const SizedBox(height: 6),
            Text(
              'Finansal verilerine bakıp aksiyon önerebilirim.\nBir şey sor ya da başlangıç noktası seç.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.text3Dark, height: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Başlangıç',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.text3Dark)),
        const SizedBox(height: 10),
        ..._starters.asMap().entries.map((entry) {
          final s = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onPick(s.text),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border1Dark),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon,
                          size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.text,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.text3Dark),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Message Bubble ───────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isUser
          ? Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(msg.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.accentText,
                          fontWeight: FontWeight.w500,
                          height: 1.45)),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarBubble(),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.85),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border:
                            Border.all(color: AppColors.border1Dark),
                      ),
                      child: MarkdownBody(
                        data: msg.content,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.text1Dark, height: 1.5),
                          strong: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                          code: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                              backgroundColor: AppColors.accentDim),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, Color(0xFF0A7DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_awesome,
          size: 14, color: AppColors.accentText),
    );
  }
}

// ── Typing Indicator ─────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AvatarBubble(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border1Dark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [0, 1, 2].map((i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final phase =
                        (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
                    final opacity = 0.3 +
                        0.7 *
                            (0.5 -
                                    0.5 *
                                        math.cos(phase * 2 * math.pi))
                                .clamp(0.0, 1.0);
                    final scale = 0.8 +
                        0.2 *
                            (0.5 -
                                    0.5 *
                                        math.cos(phase * 2 * math.pi))
                                .clamp(0.0, 1.0);
                    return Padding(
                      padding:
                          EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.text2Dark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Area ───────────────────────────────────────────────────────
class _InputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onSend;
  final List<String>? lastSuggestions;
  const _InputArea({
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.lastSuggestions,
  });

  @override
  State<_InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<_InputArea> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg0,
        border: Border(top: BorderSide(color: AppColors.border1Dark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.lastSuggestions != null &&
              widget.lastSuggestions!.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 10),
                itemCount: widget.lastSuggestions!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = widget.lastSuggestions![i];
                  return GestureDetector(
                    onTap: () => widget.onSend(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border2Dark),
                      ),
                      child: Text(s,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.text1Dark,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border1Dark),
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: const Icon(Icons.attach_file,
                      size: 18, color: AppColors.text3Dark),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.enabled ? widget.onSend : null,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.text1Dark),
                    decoration: const InputDecoration(
                      hintText: 'Paranette, finansal bir şey sor...',
                      hintStyle: TextStyle(
                          color: AppColors.text3Dark, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _hasText
                      ? GestureDetector(
                          key: const ValueKey('send'),
                          onTap: widget.enabled
                              ? () =>
                                  widget.onSend(widget.controller.text)
                              : null,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                            child: const Icon(Icons.send_rounded,
                                size: 16, color: AppColors.accentText),
                          ),
                        )
                      : Container(
                          key: const ValueKey('mic'),
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle),
                          child: const Icon(Icons.mic_outlined,
                              size: 18, color: AppColors.text3Dark),
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

// ── History Sheet ────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final VoidCallback onClose;
  const _HistorySheet({required this.onClose});

  static const _sessions = [
    (title: 'Mayıs harcama analizi', summary: 'Eğlence ve giyim limitlerini aştın...', date: 'Şimdi'),
    (title: 'Acil fon planı', summary: 'Aylık 5.500 ₺ ekledim, 6 ay içinde...', date: 'Dün'),
    (title: 'Trendyol anomali incelemesi', summary: 'Bu işlem 3.2 katı...', date: '8 May'),
    (title: 'Yaz tatili müzakeresi', summary: 'Otele indirim mektubu hazırladım', date: '5 May'),
    (title: 'Kredi yeniden yapılandırma', summary: '%6.2 → %5.4 olabilir...', date: '28 Nis'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              decoration: const BoxDecoration(
                color: AppColors.bg1,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text('Geçmiş sohbetler',
                        style: AppTextStyles.headlineSmall),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sessions.length,
                      itemBuilder: (_, i) {
                        final s = _sessions[i];
                        return Container(
                          decoration: BoxDecoration(
                            border: i > 0
                                ? const Border(
                                    top: BorderSide(
                                        color: AppColors.border1Dark))
                                : null,
                          ),
                          child: InkWell(
                            onTap: onClose,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(s.title,
                                            style:
                                                AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600)),
                                      ),
                                      Text(s.date,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors
                                                      .text3Dark)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(s.summary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color:
                                                  AppColors.text3Dark)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
