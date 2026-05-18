import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/ai_insights_sheet.dart';
import '../../../core/widgets/bottom_nav_shell.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────────────────────

final _negotiationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await DioClient.instance.get(ApiEndpoints.negotiation);
  return res.data as Map<String, dynamic>;
});

// ──────────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────────

const _letterTypes = [
  {
    'value': 'card_interest',
    'label': 'Kredi Kartı Faiz İndirimi',
    'icon': Icons.percent,
    'desc': 'Kredi kartı faiz oranının düşürülmesi talebi',
  },
  {
    'value': 'loan_restructure',
    'label': 'Kredi Yeniden Yapılandırma',
    'icon': Icons.account_balance_outlined,
    'desc': 'Kredi taksitlerinin yeniden yapılandırılması',
  },
  {
    'value': 'bank_fee_waiver',
    'label': 'Banka Ücreti İptali',
    'icon': Icons.money_off,
    'desc': 'Banka ücreti veya ceza muafiyeti talebi',
  },
  {
    'value': 'subscription_cancel',
    'label': 'Abonelik İptali / İndirim',
    'icon': Icons.cancel_outlined,
    'desc': 'Abonelik iptali veya indirim müzakeresi',
  },
  {
    'value': 'insurance_discount',
    'label': 'Sigorta Prim İndirimi',
    'icon': Icons.shield_outlined,
    'desc': 'Sigorta prim indirim talebi',
  },
  {
    'value': 'salary_raise',
    'label': 'Maaş Zam Talebi',
    'icon': Icons.trending_up,
    'desc': 'İşverene maaş artışı talebi',
  },
  {
    'value': 'other',
    'label': 'Diğer',
    'icon': Icons.edit_note,
    'desc': 'Kendi belirttiğiniz konuda müzakere',
  },
];

const _statusSequence = ['draft', 'sent', 'accepted', 'rejected'];

Map<String, dynamic> _getStatusMeta(String status, AppColorTokens c) => switch (status) {
      'sent'     => {'label': 'Gönderildi',   'icon': Icons.send_outlined,        'color': const Color(0xFF3B82F6)},
      'accepted' => {'label': 'Kabul Edildi', 'icon': Icons.check_circle_outline, 'color': c.positive},
      'rejected' => {'label': 'Reddedildi',   'icon': Icons.cancel_outlined,      'color': c.negative},
      _          => {'label': 'Taslak',       'icon': Icons.edit_outlined,        'color': c.warning},
    };

// ──────────────────────────────────────────────────────────────────────────────
// PDF helpers
// ──────────────────────────────────────────────────────────────────────────────

String _stripMarkdown(String md) => md
    .replaceAllMapped(RegExp(r'\*\*\*(.+?)\*\*\*'), (m) => m.group(1) ?? '')
    .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'),     (m) => m.group(1) ?? '')
    .replaceAllMapped(RegExp(r'\*(.+?)\*'),          (m) => m.group(1) ?? '')
    .replaceAll(RegExp(r'#{1,6}\s+'), '')
    .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ')
    .replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'),  (m) => m.group(1) ?? '')
    .replaceAllMapped(RegExp(r'`(.+?)`'),            (m) => m.group(1) ?? '')
    .trim();

Future<Uint8List> _buildPdf(Map<String, dynamic> draft) async {
  final doc       = pw.Document(title: draft['subject'] as String? ?? 'Müzakere Mektubu');
  final body      = draft['body']           as String? ?? '';
  final subject   = draft['subject']        as String? ?? 'Müzakere Mektubu';
  final recipient = draft['recipient_name'] as String? ?? '';
  final targetVal = draft['target']         as String? ?? 'other';
  final typeInfo  = _letterTypes.firstWhere(
    (t) => t['value'] == targetVal,
    orElse: () => _letterTypes.last,
  );
  final typeLabel = typeInfo['label'] as String;
  final plainBody = _stripMarkdown(body);

  final now    = DateTime.now();
  final dateTr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

  final regular = await PdfGoogleFonts.notoSansRegular();
  final bold    = await PdfGoogleFonts.notoSansBold();
  final italic  = await PdfGoogleFonts.notoSansItalic();

  final accentClr  = PdfColor.fromHex('0EA5E9');
  final textDark   = PdfColor.fromHex('0F172A');
  final textGray   = PdfColor.fromHex('64748B');
  final divColor   = PdfColor.fromHex('E2E8F0');
  final accentBg   = PdfColor.fromHex('EFF6FF');

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 48),
    theme: pw.ThemeData(
      defaultTextStyle: pw.TextStyle(font: regular, fontSize: 11, color: textDark),
    ),
    header: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Container(
                width: 7, height: 7,
                decoration: pw.BoxDecoration(color: accentClr, shape: pw.BoxShape.circle),
              ),
              pw.SizedBox(width: 7),
              pw.Text('Paranette',
                  style: pw.TextStyle(font: bold, fontSize: 15, color: textDark)),
              pw.SizedBox(width: 6),
              pw.Text('Müzakere Asistanı',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: textGray)),
            ]),
            pw.Text(dateTr,
                style: pw.TextStyle(font: regular, fontSize: 9, color: textGray)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: divColor, thickness: 1),
        pw.SizedBox(height: 14),
      ],
    ),
    footer: (ctx) => pw.Column(
      children: [
        pw.Divider(color: divColor, thickness: 0.5),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Bu mektup Paranette AI Asistanı tarafından oluşturulmuştur.',
              style: pw.TextStyle(font: italic, fontSize: 7.5, color: textGray),
            ),
            pw.Text('Sayfa ${ctx.pageNumber}/${ctx.pagesCount}',
                style: pw.TextStyle(font: regular, fontSize: 7.5, color: textGray)),
          ],
        ),
      ],
    ),
    build: (ctx) => [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: accentBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Text(typeLabel,
            style: pw.TextStyle(font: regular, fontSize: 9, color: accentClr)),
      ),
      pw.SizedBox(height: 18),
      pw.Text(subject,
          style: pw.TextStyle(font: bold, fontSize: 16, color: textDark)),
      pw.SizedBox(height: 16),
      if (recipient.isNotEmpty) ...[
        pw.Text('Sayın $recipient,',
            style: pw.TextStyle(font: regular, fontSize: 11, color: textDark)),
        pw.SizedBox(height: 14),
      ],
      pw.Text(
        plainBody,
        style: pw.TextStyle(font: regular, fontSize: 10.5, color: textDark, lineSpacing: 3),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 36),
      pw.Text('Saygılarımla,',
          style: pw.TextStyle(font: regular, fontSize: 11, color: textDark)),
      pw.SizedBox(height: 42),
      pw.Container(width: 160, height: 1, color: divColor),
      pw.SizedBox(height: 4),
      pw.Text('İmza / Ad Soyad',
          style: pw.TextStyle(font: regular, fontSize: 9, color: textGray)),
    ],
  ));

  return doc.save();
}

// ──────────────────────────────────────────────────────────────────────────────
// Main page
// ──────────────────────────────────────────────────────────────────────────────

class NegotiationPage extends ConsumerWidget {
  const NegotiationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final async = ref.watch(_negotiationProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _GeneratePage()),
          );
          ref.invalidate(_negotiationProvider);
        },
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF051929),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Yeni Mektup',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Icon(Icons.menu, size: 18, color: c.text2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Müzakere Asistanı',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.text1)),
                        Text('AI destekli taslak oluştur',
                            style: TextStyle(fontSize: 12, color: c.text3)),
                      ],
                    ),
                  ),
                  const AiInsightsButton(page: 'negotiation'),
                ],
              ),
            ),
            // Hero card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 22, color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('✦ ',
                                  style: TextStyle(
                                      color: AppColors.accent, fontSize: 10)),
                              Text('Yapay Zeka',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Banka ve abonelik şirketlerine profesyonel müzakere mektupları oluştur.',
                          style: TextStyle(
                              fontSize: 12, color: c.text2, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            // List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: c.card,
                onRefresh: () async => ref.invalidate(_negotiationProvider),
                child: async.when(
                  loading: () => const SkeletonListView(),
                  error: (e, __) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_negotiationProvider),
                  ),
                  data: (data) {
                    final drafts =
                        (data['drafts'] as List? ?? []).cast<Map<String, dynamic>>();
                    if (drafts.isEmpty) {
                      return EmptyState(
                        icon: Icons.description_outlined,
                        title: 'Henüz mektup yok',
                        subtitle:
                            'AI ile faiz indirimi, abonelik iptali ve daha fazlası için müzakere mektubu oluşturun.',
                        ctaLabel: '+ Yeni Mektup',
                        onCta: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const _GeneratePage()),
                          );
                          ref.invalidate(_negotiationProvider);
                        },
                      );
                    }

                    final accepted =
                        drafts.where((d) => d['status'] == 'accepted').length;
                    final sent =
                        drafts.where((d) => d['status'] == 'sent').length;

                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemCount: drafts.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _StatsRow(
                            total: drafts.length,
                            sent: sent,
                            accepted: accepted,
                          );
                        }
                        final draft = drafts[i - 1];
                        return _DraftCard(
                          draft: draft,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _DetailPage(draft: draft),
                              ),
                            );
                            ref.invalidate(_negotiationProvider);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats row
// ──────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int sent;
  final int accepted;
  const _StatsRow(
      {required this.total, required this.sent, required this.accepted});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        _StatChip(label: 'Toplam', value: '$total', color: c.text2),
        const SizedBox(width: 8),
        _StatChip(
            label: 'Gönderilen',
            value: '$sent',
            color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        _StatChip(label: 'Kabul', value: '$accepted', color: c.positive),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: c.text3)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Draft card
// ──────────────────────────────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  final Map<String, dynamic> draft;
  final VoidCallback onTap;
  const _DraftCard({required this.draft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final targetVal = draft['target'] as String? ?? 'other';
    final typeInfo = _letterTypes.firstWhere(
      (t) => t['value'] == targetVal,
      orElse: () => _letterTypes.last,
    );
    final status = draft['status'] as String? ?? 'draft';
    final meta = _getStatusMeta(status, c);
    final statusColor = meta['color'] as Color;
    final statusLabel = meta['label'] as String;
    final targetLabel =
        draft['target_label'] as String? ?? typeInfo['label'] as String? ?? '';
    final subject = draft['subject'] as String? ?? targetLabel;
    final body = draft['body'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeInfo['icon'] as IconData,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.text1)),
                      Text(targetLabel,
                          style: TextStyle(fontSize: 12, color: c.text3)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ]),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  body,
                  style: TextStyle(
                      fontSize: 12,
                      color: c.text2,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.arrow_forward_ios,
                    size: 11, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('Mektubu görüntüle',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Generate page (full-screen)
// ──────────────────────────────────────────────────────────────────────────────

class _GeneratePage extends StatefulWidget {
  const _GeneratePage();

  @override
  State<_GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<_GeneratePage> {
  String? _selectedType;
  final _recipientCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mektup türü seçin')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.post(
        ApiEndpoints.negotiationGenerate,
        data: {
          'target': _selectedType,
          'recipient_name': _recipientCtrl.text.trim(),
          'extra_context': _contextCtrl.text.trim(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      final responseData = res.data as Map<String, dynamic>;
      final draftRaw = responseData['draft'] as Map<String, dynamic>? ?? responseData;
      final combined = {
        ...draftRaw,
        'key_arguments': responseData['key_arguments'] ?? [],
        'success_tips': responseData['success_tips'] ?? [],
        'estimated_chance': responseData['estimated_chance'],
      };

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _DetailPage(draft: combined, isNewlyGenerated: true),
          ),
        );
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] ??
          (e.response?.data as Map?)?['message'] ??
          'Oluşturulamadı.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child:
                        Icon(Icons.arrow_back_ios_new, size: 15, color: c.text2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Müzakere Mektubu Oluştur',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.text1)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Body
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    children: [
                      // AI badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.18)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                size: 18, color: AppColors.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'AI, durumunuza özel, profesyonel ve ikna edici bir müzakere mektubu oluşturur.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: c.text2,
                                  height: 1.45),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      // Type label
                      Text('Mektup Türü',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.text3,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 12),
                      // Type grid
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _letterTypes.map((t) {
                          final isSelected = _selectedType == t['value'];
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedType = t['value'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.14)
                                    : c.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : c.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t['icon'] as IconData,
                                      size: 15,
                                      color: isSelected
                                          ? AppColors.accent
                                          : c.text2),
                                  const SizedBox(width: 6),
                                  Text(
                                    t['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.accent
                                          : c.text1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Type desc
                      if (_selectedType != null) ...[
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            key: ValueKey(_selectedType),
                            _letterTypes.firstWhere(
                                (t) => t['value'] == _selectedType)['desc']
                                as String,
                            style: TextStyle(fontSize: 12, color: c.text3),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Fields
                      _DarkTextField(
                        controller: _recipientCtrl,
                        label: 'Alıcı',
                        hint: 'ör: Garanti BBVA Müşteri Hizmetleri',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 12),
                      _DarkTextField(
                        controller: _contextCtrl,
                        label: 'Ek Bağlam (opsiyonel)',
                        hint: 'ör: 5 yıllık müşteriyim, kredi 120.000 ₺',
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                      ),
                    ],
                  ),
                  // Bottom button
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.bg.withValues(alpha: 0),
                            c.bg,
                            c.bg,
                          ],
                        ),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _generate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: const Color(0xFF051929),
                            disabledBackgroundColor:
                                AppColors.accent.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF051929)))
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            _loading ? 'AI mektup yazıyor...' : 'Mektup Oluştur',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Detail page (full-screen)
// ──────────────────────────────────────────────────────────────────────────────

class _DetailPage extends StatefulWidget {
  final Map<String, dynamic> draft;
  final bool isNewlyGenerated;
  const _DetailPage({required this.draft, this.isNewlyGenerated = false});

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  late String _status;
  bool _insightsExpanded = true;
  bool _pdfLoading = false;
  bool _statusLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.draft['status'] as String? ?? 'draft';
    // For newly generated drafts collapse insights so letter is prominent
    _insightsExpanded = !widget.isNewlyGenerated;
  }

  Map<String, dynamic> get _draft => widget.draft;
  String get _body => _draft['body'] as String? ?? '';

  // Pre-process body so single \n becomes a Markdown hard line break (two
  // trailing spaces + \n). AI output uses single newlines; standard Markdown
  // ignores them, causing lines to run together.
  String get _formattedBody {
    final raw = _body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Replace every single newline (not part of a blank-line paragraph break)
    // with two trailing spaces + newline — the Markdown hard-break syntax.
    return raw.replaceAllMapped(
      RegExp(r'(?<!\n)\n(?!\n)'),
      (_) => '  \n',
    );
  }
  String get _subject => _draft['subject'] as String? ?? 'Müzakere Mektubu';
  String get _recipient => _draft['recipient_name'] as String? ?? '';
  int? get _draftId => _draft['id'] as int?;
  List get _keyArgs => _draft['key_arguments'] as List? ?? [];
  List get _tips => _draft['success_tips'] as List? ?? [];
  dynamic get _chance => _draft['estimated_chance'];

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _body));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mektup panoya kopyalandı')),
      );
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await _buildPdf(_draft);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'muzakere-mektubu.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF oluşturulamadı')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _previewPdf() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await _buildPdf(_draft);
      if (mounted) {
        setState(() => _pdfLoading = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(_subject,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              body: PdfPreview(
                build: (_) async => bytes,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                pdfFileName: 'muzakere-mektubu.pdf',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pdfLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF oluşturulamadı')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_draftId == null) return;
    setState(() => _statusLoading = true);
    try {
      await DioClient.instance.patch(
        ApiEndpoints.negotiationStatus(_draftId!),
        data: {'status': newStatus},
      );
      if (mounted) setState(() => _status = newStatus);
    } on DioException catch (e) {
      if (mounted) {
        final msg = (e.response?.data as Map?)?['message'] ?? 'Güncellenemedi.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _showStatusSheet() async {
    final c = context.appColors;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Durum Güncelle',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.text1)),
            const SizedBox(height: 16),
            ..._statusSequence.map((s) {
              final meta = _getStatusMeta(s, c);
              final isActive = _status == s;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (!isActive) _updateStatus(s);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (meta['color'] as Color).withValues(alpha: 0.10)
                        : c.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? (meta['color'] as Color)
                          : c.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(meta['icon'] as IconData,
                        size: 18, color: meta['color'] as Color),
                    const SizedBox(width: 12),
                    Text(meta['label'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? meta['color'] as Color
                                : c.text1)),
                    const Spacer(),
                    if (isActive)
                      Icon(Icons.check_circle,
                          size: 18, color: meta['color'] as Color),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (_draftId == null) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.appColors.card,
        title: const Text('Mektubu Sil'),
        content: const Text('Bu mektubu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('İptal',
                style: TextStyle(color: context.appColors.text2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.negative,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await DioClient.instance.delete(ApiEndpoints.negotiationItem(_draftId!));
      if (mounted) Navigator.pop(context);
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silinemedi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final targetVal = _draft['target'] as String? ?? 'other';
    final typeInfo = _letterTypes.firstWhere(
      (t) => t['value'] == targetVal,
      orElse: () => _letterTypes.last,
    );
    final meta = _getStatusMeta(_status, c);
    final statusColor = meta['color'] as Color;
    final statusLabel = meta['label'] as String;
    final statusIcon = meta['icon'] as IconData;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child:
                        Icon(Icons.arrow_back_ios_new, size: 15, color: c.text2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _subject,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.text1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Overflow menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: c.text2),
                  color: c.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'delete') _delete();
                    if (v == 'copy') _copyText();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(children: [
                        Icon(Icons.copy_outlined, size: 16, color: c.text2),
                        const SizedBox(width: 8),
                        Text('Metni Kopyala',
                            style: TextStyle(fontSize: 13, color: c.text1)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: c.negative),
                        const SizedBox(width: 8),
                        Text('Sil',
                            style: TextStyle(fontSize: 13, color: c.negative)),
                      ]),
                    ),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Metadata strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(typeInfo['icon'] as IconData,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      typeInfo['label'] as String,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _statusLoading
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: statusColor))
                        : Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ]),
                ),
                if (_recipient.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _recipient,
                      style: TextStyle(fontSize: 11, color: c.text3),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // AI Insights card (collapsible)
                  if (_keyArgs.isNotEmpty || _tips.isNotEmpty || _chance != null) ...[
                    GestureDetector(
                      onTap: () => setState(
                          () => _insightsExpanded = !_insightsExpanded),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Row(children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 15, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Text('AI Analizi',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: c.text1)),
                                  if (_chance != null) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: c.positive.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _chance is num
                                              ? '${(_chance as num).round()}% başarı'
                                              : _chance.toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: c.positive)),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _insightsExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                                color: c.text3,
                              ),
                            ]),
                            if (_insightsExpanded) ...[
                              const SizedBox(height: 12),
                              if (_keyArgs.isNotEmpty) ...[
                                _SectionLabel(
                                    label: 'Temel Argümanlar',
                                    icon: Icons.format_list_bulleted),
                                const SizedBox(height: 6),
                                ..._keyArgs.map((a) => _BulletRow(
                                    text: a.toString(),
                                    color: AppColors.accent)),
                                const SizedBox(height: 10),
                              ],
                              if (_tips.isNotEmpty) ...[
                                _SectionLabel(
                                    label: 'Başarı İpuçları',
                                    icon: Icons.lightbulb_outline),
                                const SizedBox(height: 6),
                                ..._tips.map((t) => _BulletRow(
                                    text: t.toString(), color: c.positive)),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Letter body section header
                  _SectionLabel(
                      label: 'Mektup İçeriği',
                      icon: Icons.description_outlined),
                  const SizedBox(height: 10),
                  // Full markdown body
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.border),
                    ),
                    child: MarkdownBody(
                      data: _formattedBody,
                      shrinkWrap: true,
                      softLineBreak: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            fontSize: 14,
                            color: c.text1,
                            height: 1.65),
                        h1: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.text1),
                        h2: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.text1),
                        h3: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.text1),
                        strong: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent),
                        em: TextStyle(
                            fontStyle: FontStyle.italic, color: c.text2),
                        listBullet: TextStyle(fontSize: 14, color: c.text2),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                              left: BorderSide(
                                  color: AppColors.accent, width: 3)),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: c.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            // Bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(children: [
                // Copy
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.copy_outlined,
                    label: 'Kopyala',
                    onTap: _copyText,
                  ),
                ),
                const SizedBox(width: 8),
                // PDF preview/share
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    icon: _pdfLoading ? null : Icons.picture_as_pdf_outlined,
                    label: _pdfLoading ? 'PDF hazırlanıyor...' : 'PDF Görüntüle',
                    accent: true,
                    loading: _pdfLoading,
                    onTap: _pdfLoading ? null : _previewPdf,
                  ),
                ),
                const SizedBox(width: 8),
                // Status update
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.tune_outlined,
                    label: 'Durum',
                    onTap: _showStatusSheet,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool accent;
  final bool loading;
  final VoidCallback? onTap;
  const _ActionBtn({
    this.icon,
    required this.label,
    this.accent = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.accent
              : c.bg,
          borderRadius: BorderRadius.circular(12),
          border: accent ? null : Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent ? const Color(0xFF051929) : AppColors.accent,
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 18,
                color: accent ? const Color(0xFF051929) : AppColors.accent,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent ? const Color(0xFF051929) : c.text2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: c.text3)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 0, 0),
                child: Icon(icon, size: 16, color: c.text3),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: 14, color: c.text1),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: c.text3, fontSize: 13),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 13),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(children: [
      Icon(icon, size: 13, color: c.text3),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.text3,
              letterSpacing: 0.4)),
    ]);
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: c.text2, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
