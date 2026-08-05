import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final ApiClient _apiClient = ApiClient();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _targetType = 'ALL';
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/announcements/admin');
      if (mounted) {
        setState(() {
          _announcements = res['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await _apiClient.post('/announcements/admin', {
        'title': title,
        'message': message,
        'targetType': _targetType,
      });

      _titleController.clear();
      _messageController.clear();
      await _loadAnnouncements();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement broadcasted successfully! 📢'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcasting & Announcements'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: _isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Create Announcement Form
                    Text(
                      'CREATE NEW ANNOUNCEMENT',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            style: GoogleFonts.outfit(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.campaign, color: AppTheme.neonCyan),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _targetType,
                            dropdownColor: AppTheme.cardBg,
                            style: GoogleFonts.outfit(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              labelText: 'Target Audience',
                              prefixIcon: Icon(Icons.people, color: AppTheme.primaryPurple),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('All Platform Users')),
                              DropdownMenuItem(value: 'PRODUCT', child: Text('Specific Product Users')),
                              DropdownMenuItem(value: 'LANGUAGE', child: Text('Specific Language Users')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _targetType = val);
                            },
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            style: GoogleFonts.outfit(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              labelText: 'Message Body',
                              prefixIcon: Icon(Icons.message, color: AppTheme.softGrey),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _isSubmitting
                              ? const SpinKitThreeBounce(color: AppTheme.primaryPurple, size: 24)
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.send),
                                    label: const Text('Broadcast Announcement'),
                                    onPressed: _createAnnouncement,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // History
                    Text(
                      'BROADCAST HISTORY (${_announcements.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final a = _announcements[index];
                        final dateStr = DateFormat('yMMMd HH:mm').format(DateTime.parse(a['createdAt']));

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
                                    child: Text(
                                      a['title'] ?? 'Untitled',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonCyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a['targetType'] ?? 'ALL',
                                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(a['message'] ?? '', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.softGrey)),
                              const SizedBox(height: 8),
                              Text('Broadcast on $dateStr', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey)),
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
