import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_endpoints.dart';
import '../api/dio_client.dart';

const _scaffoldBg = Color(0xFF060D18);
const _cardBg     = Color(0xFF0D1B2A);
const _cardBorder = Color(0xFF1A2940);
const _accent     = Color(0xFF00D4FF);
const _text1      = Color(0xFFE8F4FF);
const _text2      = Color(0xFF8BA4BC);
const _text3      = Color(0xFF4A6478);
const _positive   = Color(0xFF0DD9A0);
const _negative   = Color(0xFFFF4D6D);
const _warning    = Color(0xFFF59E0B);

/// Maps a page name to a label shown on the AI button tooltip
const _pageLabels = <String, String>{
  'dashboard':     'Dashboard',
  'transactions':  'İşlemler',
  'budgets':       'Bütçe',
  'goals':         'Hedefler',
  'bills':         'Faturalar',
  'subscriptions': 'Abonelikler',
  'loans':         'Krediler',
  'investments':   'Yatırım',
  'cards':         'Kartlar',
  'inflation':     'Enflasyon',
  'fx_alerts':     'Kur Alarmları',
};

/// Floating AI button that opens a bottom sheet with page-specific AI insights.
/// Usage:
///   AiInsightsButton(page: 'budgets')
class AiInsightsButton extends StatelessWidget {
  final String page;
  const AiInsightsButton({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInsights(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.auto_awesome, size: 16, color: _accent),
      ),
    );
  }

  Future<void> _showInsights(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsightsSheet(page: page),
    );
  }
}

class _InsightsSheet extends StatefulWidget {
  final String page;
  const _InsightsSheet({required this.page});

  @override
  State<_InsightsSheet> createState() => _InsightsSheetState();
}

class _InsightsSheetState extends State<_InsightsSheet> {
  List<Map<String, dynamic>> _insights = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.agentPageAnalyze,
        data: {'page': widget.page},
      );
      final raw = res.data as Map<String, dynamic>;
      final list = raw['insights'] as List? ?? [];
      setState(() {
        _insights = list.cast<Map<String, dynamic>>();
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _pageLabels[widget.page] ?? widget.page;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 16, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Analiz',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700, color: _text1)),
                        Text('$label sayfası için öneriler',
                            style: const TextStyle(fontSize: 11, color: _text3)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Icon(Icons.close, size: 14, color: _text2),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: _cardBorder, height: 1),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: _LoadingPulse())
                  : _error != null
                      ? _ErrorView(onRetry: () { setState(() { _loading = true; _error = null; }); _load(); })
                      : _insights.isEmpty
                          ? const _EmptyView()
                          : ListView.separated(
                              controller: controller,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                              itemCount: _insights.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _InsightCard(insight: _insights[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final type      = insight['type'] as String? ?? 'info';
    final title     = insight['title'] as String? ?? '';
    final body      = insight['body'] as String? ?? '';
    final action    = insight['action'] as Map<String, dynamic>?;

    final (color, icon) = switch (type) {
      'alert'   => (_negative, Icons.warning_amber_rounded),
      'warning' => (_warning,  Icons.info_outline),
      'tip'     => (_positive, Icons.lightbulb_outline),
      _         => (_accent,   Icons.auto_awesome),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w400,
                    color: _text2, height: 1.5)),
          ],
          if (action != null && (action['label'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action['label'] as String,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingPulse extends StatefulWidget {
  const _LoadingPulse();
  @override
  State<_LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<_LoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Opacity(
            opacity: _anim.value,
            child: const Icon(Icons.auto_awesome, size: 40, color: _accent),
          ),
        ),
        const SizedBox(height: 16),
        const Text('AI analiz ediliyor...',
            style: TextStyle(fontSize: 13, color: _text2)),
        const SizedBox(height: 6),
        const Text('Bu işlem birkaç saniye sürebilir',
            style: TextStyle(fontSize: 11, color: _text3)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: _text3),
          const SizedBox(height: 12),
          const Text('Analiz yüklenemedi',
              style: TextStyle(fontSize: 13, color: _text2)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: const Text('Tekrar dene',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: _positive),
          SizedBox(height: 12),
          Text('Her şey yolunda!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
          SizedBox(height: 6),
          Text('Bu sayfa için şu an öneri bulunmuyor.',
              style: TextStyle(fontSize: 12, color: _text3)),
        ],
      ),
    );
  }
}
