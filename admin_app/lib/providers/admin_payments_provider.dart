import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class AdminPaymentModel {
  final String id;
  final String orderId;
  final String? paymentId;
  final int amount;
  final String currency;
  final String status;
  final String userEmail;
  final String? userName;
  final String? productName;
  final DateTime createdAt;

  AdminPaymentModel({
    required this.id,
    required this.orderId,
    this.paymentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.userEmail,
    this.userName,
    this.productName,
    required this.createdAt,
  });

  factory AdminPaymentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final profile = user['profile'] ?? {};
    final firstName = profile['firstName'] ?? '';
    final lastName = profile['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return AdminPaymentModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      paymentId: json['paymentId'],
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'CREATED',
      userEmail: user['email'] ?? 'Unknown User',
      userName: fullName.isNotEmpty ? fullName : null,
      productName: json['product'] != null ? json['product']['name'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  double get amountInRupees => amount / 100.0;
}

class AdminRefundModel {
  final String id;
  final String paymentId;
  final int amount;
  final String reason;
  final String? bankDetails;
  final String status;
  final String userEmail;
  final String? userName;
  final String? productName;
  final String? adminRemarks;
  final bool refundEligible;
  final DateTime requestedAt;

  AdminRefundModel({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    this.bankDetails,
    required this.status,
    required this.userEmail,
    this.userName,
    this.productName,
    this.adminRemarks,
    required this.refundEligible,
    required this.requestedAt,
  });

  factory AdminRefundModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final profile = user['profile'] ?? {};
    final firstName = profile['firstName'] ?? '';
    final lastName = profile['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final snapshot = json['snapshot'] ?? {};

    return AdminRefundModel(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: json['amount'] ?? 0,
      reason: json['reason'] ?? '',
      bankDetails: json['bankDetails'],
      status: json['status'] ?? 'PENDING',
      userEmail: user['email'] ?? 'Unknown User',
      userName: fullName.isNotEmpty ? fullName : null,
      productName: json['payment']?['product']?['name'],
      adminRemarks: json['adminRemarks'],
      refundEligible: snapshot['refundEligible'] ?? true,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
    );
  }

  double get amountInRupees => amount / 100.0;
}

class AdminPaymentsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AdminPaymentModel> _payments = [];
  List<AdminRefundModel> _refundRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminPaymentModel> get payments => _payments;
  List<AdminRefundModel> get refundRequests => _refundRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAdminPayments({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri(path: '/payments/admin', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await _apiClient.get(uri.toString());
      final List list = res['data']?['payments'] ?? [];
      _payments = list.map((item) => AdminPaymentModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchAdminRefundRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri(path: '/refunds/admin', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await _apiClient.get(uri.toString());
      final List list = res['data']?['requests'] ?? [];
      _refundRequests = list.map((item) => AdminRefundModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> reviewRefundRequest(String id, {required String status, String? adminRemarks}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.patch('/refunds/admin/$id/review', {
        'status': status,
        'adminRemarks': adminRemarks,
      });
      await fetchAdminRefundRequests();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
