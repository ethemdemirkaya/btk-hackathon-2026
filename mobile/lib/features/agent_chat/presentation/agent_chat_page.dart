import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/bottom_nav_shell.dart';

// ── Starters ─────────────────────────────────────────────────────────
const _starters = [
  (icon: Icons.pie_chart_outline, text: 'Bu ay nereye harcadım?'),
  (icon: Icons.flag_outlined, text: 'Hedefe ne kadar atayabilirim?'),
  (icon: Icons.warning_amber_outlined, text: 'Anomalileri göster'),
  (icon: Icons.account_balance_wallet_outlined, text: 'Bütçe öner'),
  (icon: Icons.trending_up_outlined, text: 'Finansal sağlık durumum'),
  (icon: Icons.subscriptions_outlined, text: 'Abonelik fırsatları'),
];

// ── Agent names → display labels ─────────────────────────────────────
const _agentLabels = <String, String>{
  'budget_advisor':       'Bütçe Danışmanı',
  'anomaly_detector':     'Anomali Dedektörü',
  'debt_optimizer':       'Borç Optimizasyonu',
  'forecaster':           'Tahmin Ajanı',
  'inflation_aware':      'Enflasyon Ajanı',
  'purchase_planner':     'Satın Alma Planlayıcı',
  'receipt_ocr':          'Fiş Okuyucu',
  'subscription_hunter':  'Abonelik Avcısı',
  'transaction_classifier': 'İşlem Sınıflandırıcı',
  'orchestrator':         'Orkestratör',
  'critic':               'Eleştirmen',
};

// ── Agent → quick action destination ─────────────────────────────────
const _agentRoutes = <String, (String label, IconData icon, String path)>{
  'budget_advisor':      ('Bütçe oluştur',     Icons.account_balance_wallet_outlined, '/budgets'),
  'anomaly_detector':    ('İşlemleri incele',   Icons.receipt_long_outlined,           '/transactions'),
  'debt_optimizer':      ('Borçları görüntüle', Icons.account_balance_outlined,        '/loans'),
  'forecaster':          ('Hedef ekle',         Icons.flag_outlined,                   '/goals'),
  'inflation_aware':     ('Enflasyon analizi',  Icons.trending_up_outlined,            '/inflation'),
  'subscription_hunter': ('Abonelikler',        Icons.subscriptions_outlined,          '/subscriptions'),
};

// ── Processing stages ─────────────────────────────────────────────────
enum _Stage { idle, analyzing, planning, executing, generating }

const _stageLabels = <_Stage, String>{
  _Stage.analyzing:  'Finansal veriler analiz ediliyor...',
  _Stage.planning:   'Ajan planı hazırlanıyor...',
  _Stage.executing:  'Uzman ajanlar çalışıyor...',
  _Stage.generating: 'Yanıt oluşturuluyor...',
};

// ── Message model ─────────────────────────────────────────────────────
class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime at;
  final List<String>? agentsUsed;
  final int? runId;

  const _Msg({
    required this.role,
    required this.content,
    required this.at,
    this.agentsUsed,
    this.runId,
  });
}

// ── History run ───────────────────────────────────────────────────────
class _HistoryRun {
  final int runId;
  final String sessionId;
  final String status;
  final DateTime? startedAt;
  final List<_Msg> messages;

  const _HistoryRun({
    required this.runId,
    required this.sessionId,
    required this.status,
    this.startedAt,
    required this.messages,
  });

  String get preview {
    final last = messages.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => messages.isNotEmpty ? messages.last : _Msg(role: '', content: '', at: _epoch),
    );
    if (last.content.isEmpty) return '—';
    return last.content.length > 60 ? '${last.content.substring(0, 60)}...' : last.content;
  }

  String get title {
    final user = messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => _Msg(role: '', content: 'Sohbet', at: _epoch),
    );
    if (user.content.isEmpty) return 'Sohbet';
    return user.content.length > 40 ? '${user.content.substring(0, 40)}...' : user.content;
  }

  factory _HistoryRun.fromJson(Map<String, dynamic> j) {
    final msgs = ((j['messages'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => _Msg(
              role: m['role'] as String? ?? 'user',
              content: m['content'] as String? ?? '',
              at: DateTime.tryParse(m['at'] as String? ?? '') ?? DateTime.now(),
            ))
        .toList();
    return _HistoryRun(
      runId:     (j['run_id'] as num).toInt(),
      sessionId: j['session_id'] as String? ?? '',
      status:    j['status'] as String? ?? 'completed',
      startedAt: DateTime.tryParse(j['started_at'] as String? ?? ''),
      messages:  msgs,
    );
  }
}

final _epoch = DateTime.utc(2000);

// ── Page ──────────────────────────────────────────────────────────────
class AgentChatPage extends StatefulWidget {
  const AgentChatPage({super.key});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _sessionId  = const Uuid().v4();

  final List<_Msg> _messages = [];
  _Stage _stage     = _Stage.idle;
  bool   _showHistory = false;
  Timer? _stageTimer;

  @override
  void dispose() {
    _stageTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _thinking => _stage != _Stage.idle;

  void _startStageCycle() {
    final stages = [_Stage.analyzing, _Stage.planning, _Stage.executing, _Stage.generating];
    int idx = 0;
    if (mounted) setState(() => _stage = stages[idx]);
    _stageTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      idx++;
      if (idx >= stages.length) {
        // Stick at generating forever until response arrives
        if (mounted) setState(() => _stage = _Stage.generating);
        t.cancel();
        return;
      }
      if (mounted) setState(() => _stage = stages[idx]);
    });
  }

  void _stopStageCycle() {
    _stageTimer?.cancel();
    _stageTimer = null;
    if (mounted) setState(() => _stage = _Stage.idle);
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _thinking) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', content: text.trim(), at: DateTime.now()));
    });
    _scrollToBottom();
    _startStageCycle();

    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.agentSend,
        data: {'message': text.trim(), 'session_id': _sessionId},
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      final body       = res.data as Map<String, dynamic>;
      final reply      = body['reply'] as String? ?? 'Yanıt alınamadı.';
      final agentsUsed = ((body['agents_used'] as List?) ?? []).cast<String>();
      final runId      = (body['run_id'] as num?)?.toInt();

      if (mounted) {
        _stopStageCycle();
        setState(() {
          _messages.add(_Msg(
            role: 'assistant',
            content: reply,
            at: DateTime.now(),
            agentsUsed: agentsUsed.isEmpty ? null : agentsUsed,
            runId: runId,
          ));
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _stopStageCycle();
      final msg = e.response?.data?['error'] ?? 'Ajan yanıt veremedi.';
      setState(() {
        _messages.add(_Msg(
          role: 'assistant',
          content: '⚠ $msg',
          at: DateTime.now(),
        ));
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
                  onNewChat: () {
                    _stopStageCycle();
                    setState(() => _messages.clear());
                  },
                ),
                // Agent status bar (visible while thinking)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _thinking
                      ? _AgentStatusBar(stage: _stage, key: const ValueKey('bar'))
                      : const SizedBox.shrink(key: ValueKey('nobar')),
                ),
                Expanded(
                  child: _messages.isEmpty && !_thinking
                      ? _EmptyChat(onPick: _send)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length + (_thinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _messages.length) {
                              return const _TypingIndicator();
                            }
                            final msg = _messages[i];
                            final isLast = i == _messages.length - 1;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MessageBubble(msg: msg),
                                if (msg.role == 'assistant' &&
                                    msg.agentsUsed != null &&
                                    msg.agentsUsed!.isNotEmpty) ...[
                                  _AgentMetaBadge(agentsUsed: msg.agentsUsed!),
                                  const SizedBox(height: 8),
                                ],
                                if (msg.role == 'assistant' && isLast && !_thinking)
                                  _QuickActionRow(
                                    agentsUsed: msg.agentsUsed ?? [],
                                    onTap: (path) => context.push(path),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                _InputArea(
                  controller: _inputCtrl,
                  enabled: !_thinking,
                  onSend: _send,
                ),
              ],
            ),
            if (_showHistory)
              _HistorySheet(
                currentSessionId: _sessionId,
                onClose: () => setState(() => _showHistory = false),
                onLoadSession: (msgs) {
                  setState(() {
                    _messages.clear();
                    _messages.addAll(msgs);
                    _showHistory = false;
                  });
                  _scrollToBottom();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────
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
          _IconBtn(
            icon: Icons.menu,
            onTap: () => shellScaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 10),
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
                    spreadRadius: 2),
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
                    Text('Çok-ajanlı sistem',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
          _IconBtn(icon: Icons.history, onTap: onHistory),
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

// ── Agent Status Bar ──────────────────────────────────────────────────
class _AgentStatusBar extends StatefulWidget {
  final _Stage stage;
  const _AgentStatusBar({super.key, required this.stage});

  @override
  State<_AgentStatusBar> createState() => _AgentStatusBarState();
}

class _AgentStatusBarState extends State<_AgentStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _stageLabels[widget.stage] ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: child,
            ),
            child: Icon(
              _stageIcon(widget.stage),
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: List.generate(4, (i) {
              final active = _stageIndex(widget.stage) >= i;
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _stageIndex(_Stage s) {
    switch (s) {
      case _Stage.analyzing:  return 0;
      case _Stage.planning:   return 1;
      case _Stage.executing:  return 2;
      case _Stage.generating: return 3;
      default:                return 0;
    }
  }

  IconData _stageIcon(_Stage s) {
    switch (s) {
      case _Stage.analyzing:  return Icons.search;
      case _Stage.planning:   return Icons.psychology_outlined;
      case _Stage.executing:  return Icons.hub_outlined;
      case _Stage.generating: return Icons.edit_outlined;
      default:                return Icons.loop;
    }
  }
}

// ── Agent Meta Badge ──────────────────────────────────────────────────
class _AgentMetaBadge extends StatelessWidget {
  final List<String> agentsUsed;
  const _AgentMetaBadge({required this.agentsUsed});

  @override
  Widget build(BuildContext context) {
    final labels = agentsUsed
        .map((a) => _agentLabels[a] ?? a)
        .take(3)
        .toList();
    final extra = agentsUsed.length > 3 ? agentsUsed.length - 3 : 0;

    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...labels.map((l) => _SmallChip(
                label: l,
                icon: Icons.smart_toy_outlined,
              )),
          if (extra > 0)
            _SmallChip(label: '+$extra ajan', icon: Icons.more_horiz),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SmallChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Quick Action Row ──────────────────────────────────────────────────
class _QuickActionRow extends StatelessWidget {
  final List<String> agentsUsed;
  final void Function(String path) onTap;
  const _QuickActionRow({required this.agentsUsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final actions = agentsUsed
        .where((a) => _agentRoutes.containsKey(a))
        .map((a) => _agentRoutes[a]!)
        .take(4)
        .toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions
              .map((action) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onTap(action.$3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border2Dark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(action.$2,
                                size: 13, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(action.$1,
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.text1Dark,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios,
                                size: 10, color: AppColors.text3Dark),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Empty Chat ────────────────────────────────────────────────────────
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
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.accent, Color(0xFF0A7DA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 34, color: AppColors.accentText),
            ),
            const SizedBox(height: 16),
            Text('Merhaba',
                style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.text1Dark,
                    letterSpacing: -0.02 * 22)),
            const SizedBox(height: 6),
            Text(
              'Finansal verilerine bakıp aksiyonlar önerebilirim.\nUzman ajanlarım ile birlikte çalışıyorum.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.text3Dark, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Agent pills
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _SmallChip(label: 'Bütçe Danışmanı',    icon: Icons.account_balance_wallet_outlined),
                _SmallChip(label: 'Anomali Dedektörü',  icon: Icons.warning_amber_outlined),
                _SmallChip(label: 'Tahmin Ajanı',       icon: Icons.trending_up_outlined),
                _SmallChip(label: 'Borç Optimizasyonu', icon: Icons.account_balance_outlined),
                _SmallChip(label: 'Enflasyon Ajanı',    icon: Icons.show_chart),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Hızlı başlangıç',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.text3Dark)),
        const SizedBox(height: 10),
        ..._starters.map((s) => Padding(
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
            )),
      ],
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
                const _AvatarBubble(),
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
                        border: Border.all(color: AppColors.border1Dark),
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
  const _AvatarBubble();

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

// ── Typing Indicator ──────────────────────────────────────────────────
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
          const _AvatarBubble(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
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

// ── Input Area ────────────────────────────────────────────────────────
class _InputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onSend;

  const _InputArea({
    required this.controller,
    required this.enabled,
    required this.onSend,
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border1Dark),
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: widget.enabled ? widget.onSend : null,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.text1Dark),
                  decoration: InputDecoration(
                    hintText: widget.enabled
                        ? 'Paranette\'ye bir şey sor...'
                        : 'Ajanlar çalışıyor...',
                    hintStyle: const TextStyle(
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
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText && widget.enabled
                  ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: () => widget.onSend(widget.controller.text),
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
                      key: const ValueKey('idle'),
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle),
                      child: Icon(
                        widget.enabled
                            ? Icons.mic_outlined
                            : Icons.hourglass_top_rounded,
                        size: 18,
                        color: AppColors.text3Dark,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Sheet ─────────────────────────────────────────────────────
class _HistorySheet extends StatefulWidget {
  final String currentSessionId;
  final VoidCallback onClose;
  final void Function(List<_Msg>) onLoadSession;

  const _HistorySheet({
    required this.currentSessionId,
    required this.onClose,
    required this.onLoadSession,
  });

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late Future<List<_HistoryRun>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<_HistoryRun>> _loadHistory() async {
    final res = await DioClient.instance.get(ApiEndpoints.agentHistory);
    final runs = ((res.data as Map<String, dynamic>)['runs'] as List?) ?? [];
    return runs
        .whereType<Map<String, dynamic>>()
        .map(_HistoryRun.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72),
              decoration: const BoxDecoration(
                color: AppColors.bg1,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Geçmiş sohbetler',
                              style: AppTextStyles.headlineSmall),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _future = _loadHistory();
                          }),
                          child: const Icon(Icons.refresh,
                              size: 18, color: AppColors.text3Dark),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: FutureBuilder<List<_HistoryRun>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2));
                        }
                        if (snap.hasError || !snap.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Geçmiş yüklenemedi.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(
                                        color: AppColors.text3Dark)),
                          );
                        }
                        final runs = snap.data!;
                        if (runs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Henüz sohbet yok.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(
                                        color: AppColors.text3Dark)),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: runs.length,
                          itemBuilder: (_, i) {
                            final run = runs[i];
                            final isActive =
                                run.sessionId == widget.currentSessionId;
                            return Container(
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.accentDim
                                    : Colors.transparent,
                                border: i > 0
                                    ? const Border(
                                        top: BorderSide(
                                            color:
                                                AppColors.border1Dark))
                                    : null,
                              ),
                              child: InkWell(
                                onTap: () => widget
                                    .onLoadSession(run.messages),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (isActive)
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    margin: const EdgeInsets
                                                        .only(right: 6),
                                                    decoration: const BoxDecoration(
                                                      shape:
                                                          BoxShape.circle,
                                                      color:
                                                          AppColors.accent,
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(run.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(run.preview,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: AppTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                        color: AppColors
                                                            .text3Dark)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _StatusDot(status: run.status),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed': color = const Color(0xFF22C55E); break;
      case 'failed':    color = const Color(0xFFEF4444); break;
      default:          color = AppColors.accent;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
