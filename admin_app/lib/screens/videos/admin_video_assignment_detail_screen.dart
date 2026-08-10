import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/admin_video_assignments_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminVideoAssignmentDetailScreen extends StatefulWidget {
  final String videoId;

  const AdminVideoAssignmentDetailScreen({super.key, required this.videoId});

  @override
  State<AdminVideoAssignmentDetailScreen> createState() => _AdminVideoAssignmentDetailScreenState();
}

class _AdminVideoAssignmentDetailScreenState extends State<AdminVideoAssignmentDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _detailsData;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails({String? search}) async {
    setState(() => _isLoading = true);
    final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
    final data = await assignProv.fetchVideoAssignmentDetails(widget.videoId, search: search);
    if (mounted) {
      setState(() {
        _detailsData = data;
        _isLoading = false;
      });
    }
  }

  void _showUnassignConfirmDialog(AssignedUserRecord user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Unassign Video?', style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user.fullName} (${user.email})', style: GoogleFonts.outfit(color: AppTheme.lightText)),
            const SizedBox(height: 10),
            if (user.inSnapshot)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Historical Snapshot Protected: Removing current assignment will NOT delete user\'s historical snapshot record (required for refund calculation).',
                        style: GoogleFonts.outfit(color: Colors.amber, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text('This will revoke the user\'s current video access.', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
              final res = await assignProv.unassignVideoFromUser(user.userId, widget.videoId);
              if (res != null && mounted) {
                _loadDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Video unassigned successfully'),
                    backgroundColor: AppTheme.neonCyan,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirm Unassign'),
          ),
        ],
      ),
    );
  }

  void _showForceDeleteDialog() {
    final video = _detailsData?['video'];
    final summary = _detailsData?['summary'];
    final snapshotCount = summary?['totalSnapshotUsers'] ?? 0;
    final assignedCount = summary?['totalAssignedUsers'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Force Delete Video',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${video?['title'] ?? 'This video'}"',
                style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Impact warning box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️  IRREVERSIBLE ACTION', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    _buildImpactRow(Icons.photo_camera_back_outlined, Colors.amber,
                        '$snapshotCount user snapshot(s) will be updated — their refund denominator will decrease by 1 video.'),
                    const SizedBox(height: 6),
                    _buildImpactRow(Icons.person_off_outlined, Colors.orangeAccent,
                        '$assignedCount active manual assignment(s) will be revoked.'),
                    const SizedBox(height: 6),
                    _buildImpactRow(Icons.delete_forever, Colors.redAccent,
                        'The video will be permanently deleted from the database. This cannot be undone.'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Type DELETE below to confirm:',
                style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              _ConfirmTextField(
                onConfirmed: () async {
                  Navigator.pop(ctx);
                  await _executeForceDelete();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.lightText))),
      ],
    );
  }

  Future<void> _executeForceDelete() async {
    setState(() => _isDeleting = true);
    final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
    final result = await assignProv.forceDeleteVideo(widget.videoId);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Video deleted successfully'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, 'deleted'); // Signal to parent to refresh
    } else {
      final err = assignProv.errorMessage ?? 'Failed to delete video';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context);
    final video = _detailsData?['video'];
    final summary = _detailsData?['summary'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          video != null ? video['title'] : 'Video Assignment Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading && _detailsData != null)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    tooltip: 'Force Delete Video',
                    onPressed: _showForceDeleteDialog,
                  ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: _isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : _detailsData == null
                ? const Center(child: Text('Failed to load video details', style: TextStyle(color: Colors.white)))
                : Column(
                    children: [
                      const SizedBox(height: 12),

                      // Video Info Summary Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          color: AppTheme.cardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        video['title'],
                                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                                      ),
                                    ),
                                  ],
                                ),
                                if (video['description'] != null && video['description'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(video['description'], style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildChip('Language: ${video['languageName']}', AppTheme.neonCyan),
                                    _buildChip('Duration: ${video['duration']}s', AppTheme.neonGreen),
                                    if (summary?['isSnapshotProtected'] == true)
                                      _buildChip('🔒 Snapshot Protected', Colors.amber),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // User count summary
                                Row(
                                  children: [
                                    const Icon(Icons.photo_camera_back_outlined, size: 13, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Snapshot: ${summary?['totalSnapshotUsers'] ?? 0} user(s)',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.person_outline, size: 13, color: AppTheme.neonGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Assigned: ${summary?['totalAssignedUsers'] ?? 0} user(s)',
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Search Users Input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.outfit(color: AppTheme.lightText),
                          decoration: InputDecoration(
                            hintText: 'Search assigned users by name or email...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.softGrey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppTheme.softGrey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadDetails();
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (val) => _loadDetails(search: val),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              'DIRECTLY ASSIGNED USERS',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.softGrey, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Divider(color: Colors.white10),

                      // Assigned Users List
                      Expanded(
                        child: assignProv.assignedUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_off_outlined, size: 48, color: AppTheme.softGrey.withValues(alpha: 0.5)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No users directly assigned to this video',
                                      style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 14),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '(Users may still have access via their Snapshot)',
                                      style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: assignProv.assignedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = assignProv.assignedUsers[index];
                                  return _buildUserCard(user);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildUserCard(AssignedUserRecord user) {
    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.fullName, style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (user.inSnapshot) _buildChip('In Snapshot', Colors.amber),
                _buildChip(user.isCompleted ? '✓ Watched' : '${user.watchedSecs}s watched', AppTheme.neonGreen),
              ],
            ),
          ],
        ),
        trailing: TextButton.icon(
          onPressed: () => _showUnassignConfirmDialog(user),
          icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
          label: Text('Unassign', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12)),
        ),
      ),
    );
  }
}

/// A stateful text field inside the delete dialog that enables the confirm button only when user types "DELETE"
class _ConfirmTextField extends StatefulWidget {
  final VoidCallback onConfirmed;
  const _ConfirmTextField({required this.onConfirmed});

  @override
  State<_ConfirmTextField> createState() => _ConfirmTextFieldState();
}

class _ConfirmTextFieldState extends State<_ConfirmTextField> {
  final _ctrl = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final v = _ctrl.text.trim() == 'DELETE';
      if (v != _isValid) setState(() => _isValid = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Type DELETE to confirm',
            hintStyle: GoogleFonts.outfit(color: Colors.redAccent.withValues(alpha: 0.4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isValid ? widget.onConfirmed : null,
          icon: const Icon(Icons.delete_forever, size: 18),
          label: Text('Permanently Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isValid ? Colors.redAccent : Colors.grey.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
