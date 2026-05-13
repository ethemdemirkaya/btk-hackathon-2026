import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../domain/transaction_model.dart';

class TransactionsApi {
  final Dio _dio;
  TransactionsApi(this._dio);

  Future<TransactionPage> getTransactions({
    int page = 1,
    int perPage = 20,
    String? type,
    String? from,
    String? to,
    String? category,
  }) async {
    final res = await _dio.get(ApiEndpoints.transactions, queryParameters: {
      'page': page,
      'per_page': perPage,
      if (type != null) 'type': type,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (category != null) 'category': category,
    });
    return TransactionPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransaction(String id) async {
    final res = await _dio.get(ApiEndpoints.transaction(id));
    final data = res.data as Map<String, dynamic>;
    return TransactionModel.fromJson(
        data['transaction'] as Map<String, dynamic>);
  }
}
