import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_payments_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminPaymentsProvider>(context, listen: false).fetchAdminPayments();
    });
  }

  void _onSearch() {
    Provider.of<AdminPaymentsProvider>(context, listen: false).fetchAdminPayments(
      status: _selectedStatus,
      search: _searchController.text.trim(),
    );
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
    final paymentProvider = Provider.of<AdminPaymentsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Monitoring', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            // Search & Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: AppTheme.lightText),
                      onSubmitted: (_) => _onSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search order ID, payment ID, or email...',
                        hintStyle: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: AppTheme.neonCyan),
                          onPressed: _onSearch,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AppTheme.cardBg,
                    hint: Text('Status', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12)),
                    style: GoogleFonts.outfit(color: AppTheme.lightText),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(value: 'SUCCESS', child: Text('SUCCESS')),
                      const DropdownMenuItem(value: 'CREATED', child: Text('CREATED')),
                      const DropdownMenuItem(value: 'REFUNDED', child: Text('REFUNDED')),
                      const DropdownMenuItem(value: 'FAILED', child: Text('FAILED')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
                      });
                      _onSearch();
                    },
                  ),
                ],
              ),
            ),

            // Payments List
            Expanded(
              child: paymentProvider.isLoading
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : paymentProvider.payments.isEmpty
                      ? Center(
                          child: Text(
                            'No payment records found',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => paymentProvider.fetchAdminPayments(status: _selectedStatus, search: _searchController.text.trim()),
                          color: AppTheme.primaryPurple,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: paymentProvider.payments.length,
                            itemBuilder: (context, index) {
                              final p = paymentProvider.payments[index];
                              final color = _getStatusColor(p.status);

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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.userName ?? p.userEmail,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.lightText,
                                                ),
                                              ),
                                              Text(
                                                p.userEmail,
                                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: color.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            p.status,
                                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: Colors.white12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Product:', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                        Text(p.productName ?? 'Course Package', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.lightText)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Amount:', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                        Text('₹${p.amountInRupees.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Order ID:', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                                        Text(p.orderId, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonCyan)),
                                      ],
                                    ),
                                    if (p.paymentId != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Payment ID:', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                                          Text(p.paymentId!, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.lightText)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(p.createdAt),
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
          ],
        ),
      ),
    );
  }
}
