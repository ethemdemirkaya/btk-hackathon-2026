class ApiEndpoints {
  ApiEndpoints._();

  // Emülatör için: 10.0.2.2 (host machine localhost)
  // Gerçek cihaz için: 192.168.43.125 (Wi-Fi IP)
  static const baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Auth
  static const authMe = '/auth/me';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authLogout = '/auth/logout';
  static const authLogoutAll = '/auth/logout-all';
  static String authPatchMe() => '/auth/me';

  // Dashboard
  static const dashboard = '/dashboard';

  // Transactions
  static const transactions = '/transactions';
  static String transaction(String id) => '/transactions/$id';

  // Bank connections
  static const bankConnections = '/bank-connections';
  static String bankConnection(int id) => '/bank-connections/$id';
  static String bankConnectionSync(int id) => '/bank-connections/$id/sync';

  // Cards
  static const cards = '/cards';

  // Loans
  static const loans = '/loans';

  // Bills
  static const bills = '/bills';
  static String bill(int id) => '/bills/$id';

  // Subscriptions
  static const subscriptions = '/subscriptions';
  static String subscription(int id) => '/subscriptions/$id';

  // Budgets
  static const budgets = '/budgets';
  static const budgetsAiSuggest = '/budgets/ai-suggest';
  static const budgetsAiApply = '/budgets/ai-apply';

  // Goals
  static const goals = '/goals';
  static String goal(int id) => '/goals/$id';
  static String goalAddFunds(int id) => '/goals/$id/add-funds';
  static String goalSuggest(int id) => '/goals/$id/suggest';

  // Personal debts
  static const personalDebts = '/personal-debts';
  static String personalDebt(int id) => '/personal-debts/$id';
  static String personalDebtSettle(int id) => '/personal-debts/$id/settle';

  // Investments
  static const investments = '/investments';
  static String investment(int id) => '/investments/$id';

  // FX Alerts
  static const fxAlerts = '/fx-alerts';
  static const fxAlertRates = '/fx-alerts/rates';
  static String fxAlert(int id) => '/fx-alerts/$id';

  // Agent
  static const agentSend = '/agent/send';
  static const agentHistory = '/agent/history';
  static const agentInsights = '/agent/insights';
  static String agentInsightDismiss(int id) => '/agent/insights/$id/dismiss';

  // Negotiation
  static const negotiation = '/negotiation';
  static const negotiationGenerate = '/negotiation/generate';
  static String negotiationItem(int id) => '/negotiation/$id';
  static String negotiationStatus(int id) => '/negotiation/$id/status';

  // Simulator
  static const simulator = '/simulator';
  static const simulatorCalculate = '/simulator/calculate';

  // Inflation
  static const inflation = '/inflation';

  // Calendar
  static const calendar = '/calendar';

  // Reports
  static const reportSummary = '/report/summary';
  static const reportPdf = '/report/pdf';

  // Receipts
  static const receipts = '/receipts';
  static String receipt(int id) => '/receipts/$id';
}
