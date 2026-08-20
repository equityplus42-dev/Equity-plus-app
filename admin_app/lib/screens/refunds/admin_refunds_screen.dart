import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_payments_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminPaymentsProvider>(context, listen: false).fetchAdminRefundRequests();
    });
  }

  void _reviewRequest(AdminRefundModel req, String targetStatus) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$targetStatus Refund Request',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${req.userName ?? req.userEmail}',
              style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontSize: 13),
            ),
            Text(
              'Amount: ₹${req.amountInRupees.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: GoogleFonts.outfit(color: AppTheme.lightText),
              decoration: const InputDecoration(
                labelText: 'Admin Remarks / Reason',
                hintText: 'e.g. Verified eligibility; processed via payout gateway.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetStatus == 'APPROVED' || targetStatus == 'PROCESSED'
                  ? AppTheme.neonGreen
                  : Colors.redAccent,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = Provider.of<AdminPaymentsProvider>(context, listen: false);
              final success = await provider.reviewRefundRequest(
                req.id,
                status: targetStatus,
                adminRemarks: remarksController.text.trim(),
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refund request updated to $targetStatus!'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              }
            },
            child: Text('Confirm $targetStatus', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final provider = Provider.of<AdminPaymentsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Refund Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            // Status Filter Dropdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Status:',
                    style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                  ),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AppTheme.cardBg,
                    style: GoogleFonts.outfit(color: AppTheme.lightText),
                    hint: Text('All Statuses', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                      DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('UNDER REVIEW')),
                      DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
                      DropdownMenuItem(value: 'PROCESSED', child: Text('PROCESSED')),
                      DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
                      });
                      provider.fetchAdminRefundRequests(status: val);
                    },
                  ),
                ],
              ),
            ),

            // Requests List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : provider.refundRequests.isEmpty
                      ? Center(
                          child: Text('No refund applications found', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchAdminRefundRequests(status: _selectedStatus),
                          color: AppTheme.primaryPurple,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.refundRequests.length,
                            itemBuilder: (context, index) {
                              final req = provider.refundRequests[index];
                              final color = _getStatusColor(req.status);

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
                                            req.userName ?? req.userEmail,
                                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
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
                                            req.status,
                                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(req.userEmail, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                                    const Divider(height: 20, color: Colors.white12),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Refund Amount:', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                        Text('₹${req.amountInRupees.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Snapshot Eligibility:', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                        Text(
                                          req.refundEligible ? 'Eligible (<25% / 30 Days)' : 'Ineligible',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: req.refundEligible ? AppTheme.neonGreen : Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Reason:', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.softGrey)),
                                    Text(req.reason, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText)),

                                    if (req.bankDetails != null && req.bankDetails!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'MANUAL PAYOUT DETAILS (NEFT / UPI)',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.neonCyan,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    Clipboard.setData(ClipboardData(text: req.bankDetails!));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Payout details copied to clipboard! 📋'),
                                                        backgroundColor: AppTheme.neonCyan,
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.copy, size: 14, color: AppTheme.neonCyan),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Copy',
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.neonCyan,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SelectableText(
                                              req.bankDetails!,
                                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (req.adminRemarks != null && req.adminRemarks!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Admin Remarks: ${req.adminRemarks}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber)),
                                    ],

                                    const SizedBox(height: 12),
                                    // Review Action Buttons (if pending or under review)
                                    if (req.status == 'PENDING' || req.status == 'UNDER_REVIEW' || req.status == 'APPROVED') ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (req.status == 'PENDING')
                                            TextButton(
                                              onPressed: () => _reviewRequest(req, 'UNDER_REVIEW'),
                                              child: const Text('Mark Under Review'),
                                            ),
                                          if (req.status != 'APPROVED' && req.status != 'PROCESSED') ...[
                                            OutlinedButton(
                                              onPressed: () => _reviewRequest(req, 'REJECTED'),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                              child: const Text('Reject'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => _reviewRequest(req, 'APPROVED'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
                                              child: const Text('Approve', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          if (req.status == 'APPROVED') ...[
                                            ElevatedButton.icon(
                                              onPressed: () => _reviewRequest(req, 'PROCESSED'),
                                              icon: const Icon(Icons.check_circle_outline),
                                              label: const Text('Mark Processed'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ],

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(req.requestedAt),
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                                        ),
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
