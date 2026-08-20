import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String? paymentId;
  final int amount; // in paise
  final String currency;
  final String status;
  final String? productName;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    this.paymentId,
    required this.amount,
    required this.currency,
    required this.status,
    this.productName,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      paymentId: json['paymentId'],
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'CREATED',
      productName: json['product'] != null ? json['product']['name'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  double get amountInRupees => amount / 100.0;
}

class RefundRequestModel {
  final String id;
  final String paymentId;
  final int amount;
  final String reason;
  final String? bankDetails;
  final String status;
  final String? adminRemarks;
  final DateTime requestedAt;

  RefundRequestModel({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    this.bankDetails,
    required this.status,
    this.adminRemarks,
    required this.requestedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    return RefundRequestModel(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: json['amount'] ?? 0,
      reason: json['reason'] ?? '',
      bankDetails: json['bankDetails'],
      status: json['status'] ?? 'PENDING',
      adminRemarks: json['adminRemarks'],
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
    );
  }

  double get amountInRupees => amount / 100.0;
}

class UserPaymentProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<PaymentModel> _payments = [];
  List<RefundRequestModel> _refundRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  List<RefundRequestModel> get refundRequests => _refundRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Map<String, dynamic>?> createOrder(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post('/payments/create-order', {
        'productId': productId,
      });
      _isLoading = false;
      notifyListeners();
      return res['data'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/payments/verify', {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      });
      await fetchUserPayments();
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

  Future<void> fetchUserPayments() async {
    try {
      final res = await _apiClient.get('/payments/my');
      final List list = res['data'] ?? [];
      _payments = list.map((item) => PaymentModel.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user payments: $e');
    }
  }

  Future<void> fetchUserRefundRequests() async {
    try {
      final res = await _apiClient.get('/refunds/my');
      final List list = res['data'] ?? [];
      _refundRequests = list.map((item) => RefundRequestModel.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user refund requests: $e');
    }
  }

  Future<bool> submitRefundRequest({
    required String paymentId,
    required String reason,
    String? bankDetails,
    String? additionalDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post('/refunds/request', {
        'paymentId': paymentId,
        'reason': reason,
        'bankDetails': bankDetails,
        'additionalDetails': additionalDetails,
      });
      await fetchUserRefundRequests();
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

  Future<Map<String, dynamic>?> requestCashPayment(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post('/payments/request-cash', {
        'productId': productId,
      });
      _isLoading = false;
      notifyListeners();
      return res['data'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<String?> checkPaymentStatus(String paymentId) async {
    try {
      final res = await _apiClient.get('/payments/status/$paymentId');
      if (res['data'] != null && res['data']['status'] != null) {
        return res['data']['status'];
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
    return null;
  }
}
