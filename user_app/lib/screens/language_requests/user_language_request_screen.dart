import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class UserLanguageRequestScreen extends StatefulWidget {
  const UserLanguageRequestScreen({super.key});

  @override
  State<UserLanguageRequestScreen> createState() => _UserLanguageRequestScreenState();
}

class _UserLanguageRequestScreenState extends State<UserLanguageRequestScreen> {
  final ApiClient _apiClient = ApiClient();
  final _reasonController = TextEditingController();

  List<Map<String, dynamic>> _availableLanguages = [
    {'id': 'fac44ba1-afe6-42e7-ae6a-0b13402b0832', 'name': 'English', 'code': 'en'},
    {'id': '3321e10b-d8e9-4086-b80c-ec891ea122eb', 'name': 'Hindi', 'code': 'hi'},
    {'id': '4dea7216-bd07-4bd9-9cd9-b5a6a64d4346', 'name': 'Bengali', 'code': 'bn'},
  ];
  String? _selectedLanguageId = 'fac44ba1-afe6-42e7-ae6a-0b13402b0832';
  String _currentLanguageName = 'Bengali';
  List<dynamic> _requestsHistory = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch available languages
      final langRes = await _apiClient.get('/languages');
      final List langs = langRes['data'] ?? [];

      // 2. Fetch my language requests
      final reqRes = await _apiClient.get('/language-requests/my');
      final List reqs = reqRes['data'] ?? [];

      // 3. Fetch user videos status to get current assigned language name
      final progRes = await _apiClient.get('/videos/my');
      final progData = progRes['data'] ?? {};
      final assignedLangObj = progData['assignedLanguage'];
      final String currentLang = assignedLangObj != null ? assignedLangObj['name'] : 'Bengali';
      final String? assignedLangId = assignedLangObj != null ? assignedLangObj['id'] : null;

      if (mounted) {
        final allLangs = langs.cast<Map<String, dynamic>>();
        final filterLangs = allLangs.where((l) => l['id'] != assignedLangId).toList();

        setState(() {
          _availableLanguages = filterLangs.isNotEmpty ? filterLangs : allLangs;
          if (_availableLanguages.isNotEmpty) {
            _selectedLanguageId = _availableLanguages.first['id'];
          } else {
            _selectedLanguageId = null;
          }
          _currentLanguageName = currentLang;
          _requestsHistory = reqs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLanguageName = 'Bengali';
          _isLoading = false;
        });
      }
    }
  }

  bool get _hasPendingRequest {
    return _requestsHistory.any((r) => r['status'] == 'PENDING');
  }

  Future<void> _submitRequest() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please state a reason for requesting a language change.')),
      );
      return;
    }
    if (_selectedLanguageId == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _apiClient.post('/language-requests/my', {
        'requestedLanguageId': _selectedLanguageId,
        'reason': reason,
      });

      _reasonController.clear();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language change request submitted to admin! 🌐'),
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
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Change Request'),
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
                    // Current Language Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock, color: AppTheme.primaryPurple),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Language (Locked)',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentLanguageName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Request Section
                    if (_hasPendingRequest) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You already have a pending language change request under admin review.',
                                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.lightText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Request New Language',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey(_selectedLanguageId),
                              value: _availableLanguages.any((l) => l['id'] == _selectedLanguageId)
                                  ? _selectedLanguageId
                                  : (_availableLanguages.isNotEmpty ? _availableLanguages.first['id'] : null),
                              isExpanded: true,
                              dropdownColor: AppTheme.cardBg,
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.neonCyan),
                              style: GoogleFonts.outfit(color: AppTheme.lightText, fontSize: 15),
                              decoration: const InputDecoration(
                                labelText: 'Requested Language',
                                prefixIcon: Icon(Icons.language, color: AppTheme.neonCyan),
                              ),
                              items: _availableLanguages.map((l) {
                                return DropdownMenuItem<String>(
                                  value: l['id'],
                                  child: Text(
                                    '${l['name']} (${l['code']})',
                                    style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedLanguageId = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _reasonController,
                              maxLines: 3,
                              style: GoogleFonts.outfit(color: AppTheme.lightText),
                              decoration: const InputDecoration(
                                labelText: 'Reason for Request',
                                hintText: 'Please state why you wish to change your learning language...',
                                prefixIcon: Icon(Icons.edit_note, color: AppTheme.softGrey),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _isSubmitting
                                ? const SpinKitThreeBounce(color: AppTheme.primaryPurple, size: 24)
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _submitRequest,
                                      child: const Text('Submit Request'),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Request History
                    Text(
                      'Request History',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _requestsHistory.isEmpty
                        ? Text(
                            'No previous requests.',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _requestsHistory.length,
                            itemBuilder: (context, index) {
                              final req = _requestsHistory[index];
                              final status = req['status'] ?? 'PENDING';
                              final reqDate = DateFormat('yMMMd HH:mm').format(DateTime.parse(req['requestedAt']));
                              final reqLangName = req['requestedLanguage'] != null ? req['requestedLanguage']['name'] : 'Unknown';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.glassCardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Requested: $reqLangName',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.lightText,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: status == 'APPROVED'
                                                ? AppTheme.neonGreen.withOpacity(0.15)
                                                : status == 'REJECTED'
                                                    ? Colors.redAccent.withOpacity(0.15)
                                                    : Colors.amber.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: status == 'APPROVED'
                                                  ? AppTheme.neonGreen
                                                  : status == 'REJECTED'
                                                      ? Colors.redAccent
                                                      : Colors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Reason: "${req['reason']}"', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                    if (req['adminRemarks'] != null && req['adminRemarks'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Admin Remarks: ${req['adminRemarks']}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonCyan)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text('Submitted on $reqDate', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey)),
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
