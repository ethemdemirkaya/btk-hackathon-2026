class TransactionCategory {
  final int id;
  final String name;
  final String icon;

  const TransactionCategory(
      {required this.id, required this.name, required this.icon});

  factory TransactionCategory.fromJson(Map<String, dynamic> j) =>
      TransactionCategory(
        id: j['id'] as int,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? 'tabler-tag',
      );
}

class TransactionModel {
  final String id;
  final DateTime postedAt;
  final double amount;
  final double tryAmount;
  final String description;
  final String? merchantName;
  final TransactionCategory category;
  final String channel;
  final int? installmentNo;
  final int? installmentTotal;
  final double? anomalyScore;

  const TransactionModel({
    required this.id,
    required this.postedAt,
    required this.amount,
    required this.tryAmount,
    required this.description,
    this.merchantName,
    required this.category,
    required this.channel,
    this.installmentNo,
    this.installmentTotal,
    this.anomalyScore,
  });

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;
  bool get isInstallment =>
      installmentNo != null && installmentTotal != null;

  factory TransactionModel.fromJson(Map<String, dynamic> j) =>
      TransactionModel(
        id: j['id'] as String,
        postedAt: DateTime.parse(j['posted_at'] as String),
        amount: (j['amount'] as num).toDouble(),
        tryAmount: (j['try_amount'] as num).toDouble(),
        description: j['description'] as String,
        merchantName: j['merchant_name'] as String?,
        category: TransactionCategory.fromJson(
            j['category'] as Map<String, dynamic>),
        channel: j['channel'] as String? ?? 'other',
        installmentNo: j['installment_no'] as int?,
        installmentTotal: j['installment_total'] as int?,
        anomalyScore: (j['anomaly_score'] as num?)?.toDouble(),
      );
}

class TransactionPage {
  final List<TransactionModel> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const TransactionPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory TransactionPage.fromJson(Map<String, dynamic> j) =>
      TransactionPage(
        data: ((j['data'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList(),
        currentPage:
            (j['pagination']?['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (j['pagination']?['last_page'] as num?)?.toInt() ?? 1,
        total: (j['pagination']?['total'] as num?)?.toInt() ?? 0,
      );
}
