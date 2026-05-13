class DashboardSummary {
  final double totalBalance;
  final double totalCardDebt;
  final double totalLoan;
  final double netWorth;
  final int healthScore;

  const DashboardSummary({
    required this.totalBalance,
    required this.totalCardDebt,
    required this.totalLoan,
    required this.netWorth,
    required this.healthScore,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) =>
      DashboardSummary(
        totalBalance: (j['total_balance'] as num? ?? 0).toDouble(),
        totalCardDebt: (j['total_card_debt'] as num? ?? 0).toDouble(),
        totalLoan: (j['total_loan'] as num? ?? 0).toDouble(),
        netWorth: (j['net_worth'] as num? ?? 0).toDouble(),
        healthScore: (j['health_score'] as num? ?? 0).toInt(),
      );
}

class CashFlowPoint {
  final String period;
  final double income;
  final double expenses;
  final double net;

  const CashFlowPoint({
    required this.period,
    required this.income,
    required this.expenses,
    required this.net,
  });

  factory CashFlowPoint.fromJson(Map<String, dynamic> j) => CashFlowPoint(
        period: (j['period'] ?? j['month'] ?? '') as String,
        income: (j['income'] as num? ?? 0).toDouble(),
        expenses: ((j['expenses'] ?? j['expense']) as num? ?? 0).toDouble(),
        net: (j['net'] as num? ?? 0).toDouble(),
      );
}

class CategorySpend {
  final String category;
  final double amount;
  final double percentage;

  const CategorySpend({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategorySpend.fromJson(Map<String, dynamic> j) => CategorySpend(
        category: (j['category'] ?? j['name'] ?? '') as String,
        amount: ((j['amount'] ?? j['total']) as num? ?? 0).toDouble(),
        percentage: (j['percentage'] as num? ?? 0).toDouble(),
      );
}

class PersonalInflation {
  final double personalRate;
  final double tufeRate;
  final double diff;

  const PersonalInflation({
    required this.personalRate,
    required this.tufeRate,
    required this.diff,
  });

  factory PersonalInflation.fromJson(Map<String, dynamic> j) =>
      PersonalInflation(
        personalRate: (j['personal_rate'] as num? ?? 0).toDouble(),
        tufeRate: (j['tufe_rate'] as num? ?? 0).toDouble(),
        diff: (j['diff'] as num? ?? 0).toDouble(),
      );
}

class SmartAlert {
  final String type;
  final String title;
  final String body;
  final String icon;
  final String link;

  const SmartAlert({
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    required this.link,
  });

  factory SmartAlert.fromJson(Map<String, dynamic> j) => SmartAlert(
        type: j['type'] as String? ?? 'info',
        title: j['title'] as String,
        body: j['body'] as String,
        icon: j['icon'] as String? ?? 'tabler-info-circle',
        link: j['link'] as String? ?? '/',
      );
}

class BudgetSummaryItem {
  final String category;
  final double budgeted;
  final double spent;
  final double remaining;
  final double pct;
  final bool overBudget;

  const BudgetSummaryItem({
    required this.category,
    required this.budgeted,
    required this.spent,
    required this.remaining,
    required this.pct,
    required this.overBudget,
  });

  factory BudgetSummaryItem.fromJson(Map<String, dynamic> j) =>
      BudgetSummaryItem(
        category: (j['category'] ?? j['name'] ?? '') as String,
        budgeted: ((j['budgeted'] ?? j['amount']) as num? ?? 0).toDouble(),
        spent: (j['spent'] as num? ?? 0).toDouble(),
        remaining: (j['remaining'] as num? ?? 0).toDouble(),
        pct: (j['pct'] as num? ?? 0).toDouble(),
        overBudget: j['over_budget'] as bool? ?? false,
      );
}

class DashboardData {
  final DashboardSummary summary;
  final List<CashFlowPoint> cashFlow;
  final List<CategorySpend> categorySpend;
  final PersonalInflation? personalInflation;
  final List<SmartAlert> smartAlerts;
  final List<BudgetSummaryItem> budgetSummary;

  const DashboardData({
    required this.summary,
    required this.cashFlow,
    required this.categorySpend,
    this.personalInflation,
    required this.smartAlerts,
    required this.budgetSummary,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final inflationJson = j['personal_inflation'] as Map<String, dynamic>?;
    final hasInflation = inflationJson != null &&
        inflationJson['personal_rate'] != null;
    return DashboardData(
      summary: DashboardSummary.fromJson(
          j['summary'] as Map<String, dynamic>),
      cashFlow: (j['cash_flow'] as List? ?? [])
          .map((e) => CashFlowPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      categorySpend: (j['category_spend'] as List? ?? [])
          .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
          .toList(),
      personalInflation: hasInflation
          ? PersonalInflation.fromJson(inflationJson)
          : null,
      smartAlerts: (j['smart_alerts'] as List? ?? [])
          .map((e) => SmartAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      budgetSummary: (j['budget_summary'] as List? ?? [])
          .map((e) =>
              BudgetSummaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
