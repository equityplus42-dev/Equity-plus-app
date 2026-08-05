import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/admin/audit-logs');
      if (mounted) {
        setState(() {
          _logs = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: _isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : RefreshIndicator(
                onRefresh: _loadAuditLogs,
                color: AppTheme.primaryPurple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITICAL PLATFORM EVENTS (${_logs.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _logs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Text('No audit logs recorded yet.', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                final action = log['action'] ?? 'EVENT';
                                final dateStr = DateFormat('yMMMd HH:mm:ss').format(DateTime.parse(log['createdAt']));

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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: action.contains('BLOCK') || action.contains('DELETE')
                                                  ? Colors.redAccent.withOpacity(0.15)
                                                  : AppTheme.neonCyan.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              action,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: action.contains('BLOCK') || action.contains('DELETE')
                                                    ? Colors.redAccent
                                                    : AppTheme.neonCyan,
                                              ),
                                            ),
                                          ),
                                          Text(dateStr, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (log['user'] != null)
                                        Text(
                                          'User: ${log['user']['name']} (${log['user']['email']})',
                                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                                        ),
                                      if (log['details'] != null && log['details'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Details: ${log['details']}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                      ],
                                      if (log['ipAddress'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text('IP: ${log['ipAddress']}', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey)),
                                      ]
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
