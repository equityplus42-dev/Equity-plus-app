import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/user_payment_provider.dart';
import '../../core/theme/app_theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserPaymentProvider>(context, listen: false).fetchUserPayments();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return AppTheme.neonGreen;
      case 'PENDING':
      case 'CREATED':
        return Colors.amber;
      case 'REFUNDED':
        return AppTheme.neonCyan;
      case 'FAILED':
      case 'VERIFICATION_FAILED':
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return AppTheme.softGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<UserPaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: paymentProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : paymentProvider.payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 70, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No Payment Records Found',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your transaction receipts will appear here.',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => paymentProvider.fetchUserPayments(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: paymentProvider.payments.length,
                      itemBuilder: (context, index) {
                        final payment = paymentProvider.payments[index];
                        final color = _getStatusColor(payment.status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      payment.productName ?? 'Product Access',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: color.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      payment.status,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Amount Paid:',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                                  ),
                                  Text(
                                    '₹${payment.amountInRupees.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order ID:',
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      payment.orderId,
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.lightText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (payment.paymentId != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Payment ID:',
                                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        payment.paymentId!,
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonCyan),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt),
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
