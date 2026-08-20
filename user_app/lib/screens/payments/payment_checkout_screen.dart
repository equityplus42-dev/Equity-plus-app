import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:js' as js;
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
    final authUser = Provider.of<AuthProvider>(context, listen: false).user;
    final targetProductId = _productId ?? 'default-product';

    try {
      final orderData = await paymentProv.createOrder(targetProductId);
      if (orderData == null) {
        throw Exception(paymentProv.errorMessage ?? 'Failed to create payment order.');
      }

      final String orderId = orderData['orderId'];
      final String keyId = orderData['keyId'] ?? 'rzp_test_TMoIsgVOjmykWT';

      if (kIsWeb) {
        try {
          if (js.context.hasProperty('launchRazorpayCheckout')) {
            js.context.callMethod('launchRazorpayCheckout', [
              keyId,
              orderId,
              _amountInRupees * 100, // paise
              _productName,
              'Membership Activation',
              authUser?.email ?? '',
              authUser?.phoneNumber ?? '',
              js.allowInterop((paymentId, orderIdRes, signature) async {
                final success = await paymentProv.verifyPayment(
                  orderId: orderIdRes.toString(),
                  paymentId: paymentId.toString(),
                  signature: signature.toString(),
                );

                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                  if (success) {
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(paymentProv.errorMessage ?? 'Payment verification failed'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }),
              js.allowInterop((errorMsg) {
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg.toString()),
                      backgroundColor: Colors.amber[800],
                    ),
                  );
                }
              }),
            ]);
            return;
          }
        } catch (jsErr) {
          debugPrint('JS launch error: $jsErr');
        }
      }

      // Fallback Simulated Modal
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
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (bsContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.softGrey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payment, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Razorpay Secure Checkout',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Text(
                        'Key ID: $keyId',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID:', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13)),
                        Text(orderId, style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Payable:', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13)),
                        Text('₹$_amountInRupees.00', style: GoogleFonts.outfit(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(bsContext);
                  final String mockPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
                  final String mockSig = '${orderId}_${mockPaymentId}_valid';

                  final success = await paymentProv.verifyPayment(
                    orderId: orderId,
                    paymentId: mockPaymentId,
                    signature: mockSig,
                  );

                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment Verified! Redirecting to Dashboard... 🎉'),
                          backgroundColor: AppTheme.neonGreen,
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
                          content: Text(paymentProv.errorMessage ?? 'Payment verification failed'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text('Simulate Successful Razorpay Payment (₹$_amountInRupees)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(bsContext);
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
        );
      },
    );
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
