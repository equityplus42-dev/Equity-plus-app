import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/user_payment_provider.dart';
import '../../providers/user_video_provider.dart';
import '../../core/theme/app_theme.dart';

class UserRefundRequestScreen extends StatefulWidget {
  const UserRefundRequestScreen({super.key});

  @override
  State<UserRefundRequestScreen> createState() => _UserRefundRequestScreenState();
}

class _UserRefundRequestScreenState extends State<UserRefundRequestScreen> {
  final _reasonController = TextEditingController();
  final _bankController = TextEditingController();
  PaymentModel? _selectedPayment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
      await paymentProv.fetchUserPayments();
      await paymentProv.fetchUserRefundRequests();
      final videoProv = Provider.of<UserVideoProvider>(context, listen: false);
      await videoProv.fetchUserVideos();

      if (paymentProv.payments.isNotEmpty) {
        setState(() {
          _selectedPayment = paymentProv.payments.firstWhere(
            (p) => p.status == 'SUCCESS',
            orElse: () => paymentProv.payments.first,
          );
        });
      }
    });
  }

  void _submitRefund() async {
    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a successful payment transaction.')),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for your refund request.')),
      );
      return;
    }

    final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
    final success = await paymentProv.submitRefundRequest(
      paymentId: _selectedPayment!.id,
      reason: reason,
      bankDetails: _bankController.text.trim(),
    );

    if (success && mounted) {
      _reasonController.clear();
      _bankController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund request submitted successfully! Admin will review your application. 🎉'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
      case 'PROCESSED':
        return AppTheme.neonGreen;
      case 'PENDING':
      case 'UNDER_REVIEW':
        return Colors.amber;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return AppTheme.softGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProv = Provider.of<UserPaymentProvider>(context);
    final videoProv = Provider.of<UserVideoProvider>(context);
    final isEligible = videoProv.snapshot?.refundEligible ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Refund Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refund Eligibility Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEligible
                      ? AppTheme.neonGreen.withOpacity(0.08)
                      : Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEligible
                        ? AppTheme.neonGreen.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEligible ? Icons.verified_user_outlined : Icons.report_problem_outlined,
                      color: isEligible ? AppTheme.neonGreen : Colors.redAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEligible ? 'ELIGIBLE FOR REFUND' : 'REFUND ELIGIBILITY EXPIRED',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isEligible ? AppTheme.neonGreen : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEligible
                                ? 'You are within the 25% watch limit and 30 days window.'
                                : 'Watching ≥25% snapshot content or completing 30 days voids refund eligibility.',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Request Form (Only if eligible)
              if (isEligible) ...[
                Text(
                  'SUBMIT REFUND APPLICATION',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCardDecoration(),
                  child: Column(
                    children: [
                      // Select Payment Dropdown
                      DropdownButtonFormField<PaymentModel>(
                        value: _selectedPayment,
                        dropdownColor: AppTheme.cardBg,
                        style: GoogleFonts.outfit(color: AppTheme.lightText),
                        decoration: const InputDecoration(
                          labelText: 'Select Transaction',
                          prefixIcon: Icon(Icons.payment, color: AppTheme.primaryPurple),
                        ),
                        items: paymentProv.payments
                            .where((p) => p.status == 'SUCCESS')
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.productName ?? "Product"} (₹${p.amountInRupees.toStringAsFixed(0)})'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPayment = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _reasonController,
                        maxLines: 2,
                        style: GoogleFonts.outfit(color: AppTheme.lightText),
                        decoration: const InputDecoration(
                          labelText: 'Reason for Refund',
                          prefixIcon: Icon(Icons.edit_note, color: AppTheme.neonCyan),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _bankController,
                        style: GoogleFonts.outfit(color: AppTheme.lightText),
                        decoration: const InputDecoration(
                          labelText: 'Bank Account / UPI Details for Payout',
                          prefixIcon: Icon(Icons.account_balance, color: AppTheme.neonGreen),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: paymentProv.isLoading ? null : _submitRefund,
                          icon: paymentProv.isLoading
                              ? const SpinKitRing(color: Colors.white, size: 20)
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            paymentProv.isLoading ? 'Submitting...' : 'Submit Refund Request',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Previous Refund Requests History
              Text(
                'YOUR REFUND REQUEST HISTORY',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              paymentProv.refundRequests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No prior refund requests.',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paymentProv.refundRequests.length,
                      itemBuilder: (context, index) {
                        final req = paymentProv.refundRequests[index];
                        final color = _getStatusColor(req.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Amount: ₹${req.amountInRupees.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: color.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${req.reason}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                              ),
                              if (req.adminRemarks != null && req.adminRemarks!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Admin Remarks: ${req.adminRemarks}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonCyan,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(req.requestedAt),
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
