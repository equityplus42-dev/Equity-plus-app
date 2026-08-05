import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_language_requests_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminLanguageRequestsScreen extends StatefulWidget {
  const AdminLanguageRequestsScreen({super.key});

  @override
  State<AdminLanguageRequestsScreen> createState() => _AdminLanguageRequestsScreenState();
}

class _AdminLanguageRequestsScreenState extends State<AdminLanguageRequestsScreen> {
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminLanguageRequestsProvider>(context, listen: false)
          .fetchRequests(status: _selectedStatus);
    });
  }

  void _showApprovalOptionsDialog(LanguageRequestModel req) {
    String chosenOption = 'OPTION_A';
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Approve Language Change for ${req.userName}',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Changing language may affect existing learning progress & snapshot.',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.lightText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Snapshot Strategy:',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.softGrey),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  value: 'OPTION_A',
                  groupValue: chosenOption,
                  activeColor: AppTheme.primaryPurple,
                  title: Text('OPTION A: Keep existing snapshot', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.lightText)),
                  subtitle: Text('Current video snapshot remains unchanged.', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => chosenOption = val);
                  },
                ),
                RadioListTile<String>(
                  value: 'OPTION_B',
                  groupValue: chosenOption,
                  activeColor: AppTheme.neonCyan,
                  title: Text('OPTION B: Reset snapshot & progress', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                  subtitle: Text('Purges snapshot & progress. Creates new snapshot on user\'s next entry.', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => chosenOption = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksController,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Admin Remarks (Optional)',
                    prefixIcon: Icon(Icons.comment, color: AppTheme.softGrey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
              onPressed: () async {
                final provider = Provider.of<AdminLanguageRequestsProvider>(context, listen: false);
                final success = await provider.reviewRequest(
                  req.id,
                  status: 'APPROVED',
                  adminRemarks: remarksController.text.trim(),
                  resetProgressOption: chosenOption,
                );

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language request approved for ${req.userName}!'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              },
              child: const Text('Confirm Approval'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(LanguageRequestModel req) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Reject Request for ${req.userName}',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: remarksController,
          style: GoogleFonts.outfit(color: AppTheme.lightText),
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            prefixIcon: Icon(Icons.error_outline, color: Colors.redAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final provider = Provider.of<AdminLanguageRequestsProvider>(context, listen: false);
              final success = await provider.reviewRequest(
                req.id,
                status: 'REJECTED',
                adminRemarks: remarksController.text.trim(),
              );

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request rejected for ${req.userName}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reqProvider = Provider.of<AdminLanguageRequestsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Change Requests'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['PENDING', 'APPROVED', 'REJECTED', 'ALL'].map((st) {
                  final isSelected = _selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryPurple,
                      backgroundColor: AppTheme.cardBg,
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppTheme.lightText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = st;
                          });
                          reqProvider.fetchRequests(status: st);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10),

            Expanded(
              child: reqProvider.isLoading
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : reqProvider.requests.isEmpty
                      ? Center(
                          child: Text(
                            'No language change requests found',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reqProvider.requests.length,
                          itemBuilder: (context, index) {
                            final req = reqProvider.requests[index];
                            final dateStr = DateFormat('yMMMd HH:mm').format(DateTime.parse(req.requestedAt));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                                          req.userName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.lightText,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: req.status == 'APPROVED'
                                              ? AppTheme.neonGreen.withOpacity(0.15)
                                              : req.status == 'REJECTED'
                                                  ? Colors.redAccent.withOpacity(0.15)
                                                  : Colors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          req.status,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: req.status == 'APPROVED'
                                                ? AppTheme.neonGreen
                                                : req.status == 'REJECTED'
                                                    ? Colors.redAccent
                                                    : Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(req.userEmail, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Text('${req.currentLanguageName} ', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.softGrey)),
                                      const Icon(Icons.arrow_forward, size: 14, color: AppTheme.neonCyan),
                                      Text(' ${req.requestedLanguageName}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Reason: "${req.reason}"',
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText, fontStyle: FontStyle.italic),
                                    ),
                                  ),

                                  if (req.adminRemarks != null && req.adminRemarks!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text('Admin Remarks: ${req.adminRemarks}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                                  ],

                                  const SizedBox(height: 8),
                                  Text('Requested on $dateStr', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),

                                  if (req.status == 'PENDING') ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                                            onPressed: () => _showRejectDialog(req),
                                            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
                                            onPressed: () => _showApprovalOptionsDialog(req),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
