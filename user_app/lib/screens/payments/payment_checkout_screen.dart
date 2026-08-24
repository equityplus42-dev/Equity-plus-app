import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_payment_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  bool _isLoadingProduct = true;
  String? _productId;
  String _productName = 'Vridhi Network Membership';
  int _amountInRupees = 1000;
  bool _isProcessing = false;

  // Cash approval waiting state & polling
  String? _pendingCashPaymentId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchDefaultProductAndCheckPendingCash();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDefaultProductAndCheckPendingCash() async {
    try {
      final res = await ApiClient().get('/products');
      final List list = res['data'] ?? [];
      if (list.isNotEmpty) {
        final available = list.firstWhere(
          (p) => p['status'] == 'AVAILABLE',
          orElse: () => list.first,
        );
        _productId = available['id'];
        _productName = available['name'] ?? 'Vridhi Network Membership';
        _amountInRupees = available['price'] ?? 1000;
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    // Check if user already has a pending cash approval payment
    try {
      final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
      await paymentProv.fetchUserPayments();
      final pendingCash = paymentProv.payments.firstWhere(
        (p) => p.status == 'PENDING_CASH_APPROVAL',
        orElse: () => PaymentModel(
          id: '',
          orderId: '',
          amount: 0,
          currency: 'INR',
          status: 'NONE',
          createdAt: DateTime.now(),
        ),
      );

      if (pendingCash.id.isNotEmpty) {
        _pendingCashPaymentId = pendingCash.id;
        _startPollingCashStatus(pendingCash.id);
      }
    } catch (e) {
      debugPrint('Error checking pending cash payments: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingProduct = false;
      });
    }
  }

  void _startPollingCashStatus(String paymentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
      final status = await paymentProv.checkPaymentStatus(paymentId);

      if (status == 'SUCCESS') {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Cash Payment Approved by Admin! Redirecting to Dashboard...'),
              backgroundColor: AppTheme.neonGreen,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _processCashPaymentRequest() async {
    setState(() {
      _isProcessing = true;
    });

    final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
    final targetProductId = _productId ?? 'default-product';

    try {
      final cashData = await paymentProv.requestCashPayment(targetProductId);
      if (cashData == null || cashData['id'] == null) {
        throw Exception(paymentProv.errorMessage ?? 'Failed to submit cash payment request.');
      }

      final String paymentId = cashData['id'];

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _pendingCashPaymentId = paymentId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash payment request sent to Admin! Waiting for approval... 💵'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );

      _startPollingCashStatus(paymentId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _processRazorpayPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
    final targetProductId = _productId ?? 'default-product';

    try {
      final orderData = await paymentProv.createOrder(targetProductId);
      if (orderData == null) {
        throw Exception(paymentProv.errorMessage ?? 'Failed to create payment order.');
      }

      final String orderId = orderData['orderId'];
      final String keyId = orderData['keyId'] ?? 'rzp_test_TMoIsgVOjmykWT';

      if (!mounted) return;
      _showSimulatedCheckoutModal(orderId, keyId, paymentProv);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showSimulatedCheckoutModal(String orderId, String keyId, UserPaymentProvider paymentProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131129),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bsContext) {
        return _RazorpayCheckoutModal(
          orderId: orderId,
          keyId: keyId,
          amountInRupees: _amountInRupees,
          productName: _productName,
          paymentProv: paymentProv,
          onSuccess: () {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Razorpay Payment Verified! Redirecting to Dashboard... 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (route) => false,
              );
            }
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  Future<void> _bypassPaymentDemo() async {
    setState(() {
      _isProcessing = true;
    });

    final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
    final targetProductId = _productId ?? 'default-product';

    try {
      final orderData = await paymentProv.createOrder(targetProductId);
      if (orderData == null) {
        throw Exception(paymentProv.errorMessage ?? 'Failed to initialize demo order.');
      }

      final String orderId = orderData['orderId'];
      final String bypassPaymentId = 'pay_demo_bypass_${DateTime.now().millisecondsSinceEpoch}';

      final success = await paymentProv.verifyPayment(
        orderId: orderId,
        paymentId: bypassPaymentId,
        signature: 'demo_bypass',
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Bypassed (Demo Mode)! Access granted to Dashboard 🚀'),
            backgroundColor: AppTheme.neonGreen,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProv.errorMessage ?? 'Demo bypass failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: Center(
            child: _isLoadingProduct
                ? const SpinKitRing(color: AppTheme.primaryPurple)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Badge
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _pendingCashPaymentId != null
                                ? Colors.amber.withOpacity(0.15)
                                : AppTheme.neonGreen.withOpacity(0.15),
                            border: Border.all(
                              color: _pendingCashPaymentId != null
                                  ? Colors.amber.withOpacity(0.4)
                                  : AppTheme.neonGreen.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            _pendingCashPaymentId != null
                                ? Icons.hourglass_top_rounded
                                : Icons.card_membership_rounded,
                            size: 60,
                            color: _pendingCashPaymentId != null ? Colors.amber : AppTheme.neonGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pendingCashPaymentId != null
                              ? 'Waiting for Cash Approval'
                              : 'Membership Activation',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _pendingCashPaymentId != null
                              ? 'Your cash payment request is submitted. Once the Admin clicks approve, you will enter the dashboard automatically.'
                              : 'Complete payment to activate your referral account & unlock your dashboard.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.softGrey,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // If pending cash payment approval, show Waiting Card
                        if (_pendingCashPaymentId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.glassCardDecoration().copyWith(
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                const SpinKitFadingCircle(color: Colors.amber, size: 50),
                                const SizedBox(height: 16),
                                Text(
                                  'CASH PAYMENT REQUEST SENT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Request ID: $_pendingCashPaymentId',
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Amount: ₹$_amountInRupees.00',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Please hand over ₹$_amountInRupees cash to the Administrator. As soon as the Admin approves your payment in their app, this page will automatically redirect to your Dashboard.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _pendingCashPaymentId = null;
                                _pollingTimer?.cancel();
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Change Payment Method'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ] else ...[
                          // Summary Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.glassCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'SELECTED PLAN',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.softGrey,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryPurple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        'REFERRAL ACTIVATED',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _productName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Account: ${authUser?.email ?? "New User"}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppTheme.neonCyan,
                                  ),
                                ),
                                const Divider(height: 28, color: Colors.white12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Payable Amount:',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: AppTheme.softGrey,
                                      ),
                                    ),
                                    Text(
                                      '₹$_amountInRupees.00',
                                      style: GoogleFonts.outfit(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Action Buttons
                          if (_isProcessing)
                            const SpinKitThreeBounce(color: AppTheme.primaryPurple, size: 36)
                          else ...[
                            // Razorpay Payment Button
                            ElevatedButton.icon(
                              onPressed: _processRazorpayPayment,
                              icon: const Icon(Icons.payment, size: 22),
                              label: Text(
                                'Pay ₹$_amountInRupees via Razorpay',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Paid in Cash Option (NEWLY REQUESTED)
                            ElevatedButton.icon(
                              onPressed: _processCashPaymentRequest,
                              icon: const Icon(Icons.payments_outlined, size: 22, color: Colors.black),
                              label: Text(
                                'Paid in Cash (Offline Request)',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonGreen,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // DEMO BYPASS BUTTON
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.bolt, color: Colors.amber, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'DEMO TESTING ACCESS',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _bypassPaymentDemo,
                                    icon: const Icon(Icons.card_membership, color: Colors.black),
                                    label: Text(
                                      'Bypass Payment (Demo Mode)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RazorpayCheckoutModal extends StatefulWidget {
  final String orderId;
  final String keyId;
  final int amountInRupees;
  final String productName;
  final UserPaymentProvider paymentProv;
  final VoidCallback onSuccess;

  const _RazorpayCheckoutModal({
    required this.orderId,
    required this.keyId,
    required this.amountInRupees,
    required this.productName,
    required this.paymentProv,
    required this.onSuccess,
  });

  @override
  State<_RazorpayCheckoutModal> createState() => _RazorpayCheckoutModalState();
}

class _RazorpayCheckoutModalState extends State<_RazorpayCheckoutModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _upiController = TextEditingController(text: 'user@upi');
  final TextEditingController _cardNumberController =
      TextEditingController(text: '4111 1111 1111 1111');
  final TextEditingController _cardExpiryController = TextEditingController(text: '12/28');
  final TextEditingController _cardCvvController = TextEditingController(text: '123');
  final TextEditingController _cardNameController = TextEditingController(text: 'VRIDHI Member');

  String _selectedBank = 'HDFC Bank';
  String _selectedWallet = 'Paytm Wallet';
  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _completeRazorpayTransaction(String method, {String? details}) async {
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    final String mockPaymentId = 'pay_rzp_${method.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
    final String mockSig = '${widget.orderId}_${mockPaymentId}_valid';

    final success = await widget.paymentProv.verifyPayment(
      orderId: widget.orderId,
      paymentId: mockPaymentId,
      signature: mockSig,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        setState(() {
          _errorMsg = widget.paymentProv.errorMessage ?? 'Payment verification failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upiPayload =
        'upi://pay?pa=vridhi@razorpay&pn=VRIDHI%20Network&am=${widget.amountInRupees}&cu=INR&tr=${widget.orderId}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Badge & Order Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.blue, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Razorpay',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TEST MODE',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Order: ${widget.orderId}',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${widget.amountInRupees}.00',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                  Text(
                    'INR',
                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_errorMsg != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Navigation Tabs Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.neonCyan,
              labelColor: AppTheme.neonCyan,
              unselectedLabelColor: AppTheme.softGrey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'UPI / QR'),
                Tab(icon: Icon(Icons.credit_card_rounded, size: 18), text: 'Card'),
                Tab(icon: Icon(Icons.account_balance_rounded, size: 18), text: 'Netbanking'),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 18), text: 'Wallets'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 0: UPI & QR CODE
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: upiPayload,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan QR code with GPay, PhonePe, Paytm, or BHIM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText),
                      ),
                      const SizedBox(height: 16),

                      // Direct UPI App Launch Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildUpiAppButton('PhonePe', Colors.purple, () => _completeRazorpayTransaction('PHONEPE')),
                          _buildUpiAppButton('Google Pay', Colors.blue, () => _completeRazorpayTransaction('GPAY')),
                          _buildUpiAppButton('Paytm', Colors.cyan, () => _completeRazorpayTransaction('PAYTM')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Or Enter VPA
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _upiController,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter UPI ID (e.g. name@upi)',
                                hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _completeRazorpayTransaction('UPI_ID', details: _upiController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonCyan,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Pay UPI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // TAB 1: CREDIT / DEBIT CARD
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Number', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _cardNumberController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.credit_card, color: AppTheme.softGrey),
                          hintText: '4111 1111 1111 1111',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expiry (MM/YY)', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _cardExpiryController,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '12/28',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CVV', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _cardCvvController,
                                  obscureText: true,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '123',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Cardholder Name', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _cardNameController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Name on card',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _completeRazorpayTransaction('CARD'),
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text('Pay ₹${widget.amountInRupees} via Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: NETBANKING
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Popular Indian Banks', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildBankCard('HDFC Bank', Icons.account_balance),
                          _buildBankCard('State Bank of India', Icons.account_balance_outlined),
                          _buildBankCard('ICICI Bank', Icons.storefront),
                          _buildBankCard('Axis Bank', Icons.domain),
                          _buildBankCard('Kotak Mahindra Bank', Icons.account_balance_wallet),
                          _buildBankCard('Punjab National Bank', Icons.location_city),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _completeRazorpayTransaction('NETBANKING', details: _selectedBank),
                        icon: const Icon(Icons.double_arrow_rounded, size: 18),
                        label: Text('Pay ₹${widget.amountInRupees} with $_selectedBank'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 3: WALLETS
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Wallet Provider', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      ...['Paytm Wallet', 'PhonePe Wallet', 'Amazon Pay', 'Mobikwik'].map((wallet) {
                        final isSelected = _selectedWallet == wallet;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryPurple : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: isSelected ? AppTheme.neonCyan : AppTheme.softGrey,
                            ),
                            title: Text(wallet, style: GoogleFonts.outfit(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppTheme.neonCyan)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedWallet = wallet;
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _completeRazorpayTransaction('WALLET', details: _selectedWallet),
                        icon: const Icon(Icons.account_balance_wallet, size: 18),
                        label: Text('Pay ₹${widget.amountInRupees} using $_selectedWallet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiAppButton(String name, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(Icons.smartphone, color: color, size: 24),
            const SizedBox(height: 4),
            Text(name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(String bankName, IconData icon) {
    final isSelected = _selectedBank == bankName;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBank = bankName;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.neonCyan : AppTheme.softGrey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bankName,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
