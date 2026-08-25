import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/admin_video_assignments_provider.dart';
import '../../providers/admin_languages_provider.dart';
import '../../providers/admin_users_provider.dart';
import '../../core/theme/app_theme.dart';
import 'admin_video_assignment_detail_screen.dart';

class AdminVideoAssignmentsScreen extends StatefulWidget {
  const AdminVideoAssignmentsScreen({super.key});

  @override
  State<AdminVideoAssignmentsScreen> createState() => _AdminVideoAssignmentsScreenState();
}

class _AdminVideoAssignmentsScreenState extends State<AdminVideoAssignmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLanguageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assignProvider = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
      assignProvider.fetchDashboardStats();
      assignProvider.fetchVideoAssignments();
      Provider.of<AdminLanguagesProvider>(context, listen: false).fetchLanguages();
      Provider.of<AdminUsersProvider>(context, listen: false).fetchUsers();
    });
  }

  void _showAssignDialog(VideoAssignmentItem item) {
    final usersProvider = Provider.of<AdminUsersProvider>(context, listen: false);
    final rawUsers = usersProvider.users.where((u) => u.isApproved && u.isActive).toList();

    // Deduplicate users by ID to prevent DropdownButton duplicate value assertion error
    final Map<String, dynamic> uniqueUsersMap = {};
    for (final u in rawUsers) {
      uniqueUsersMap[u.id] = u;
    }
    final users = uniqueUsersMap.values.toList();

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active approved users available to assign.')),
      );
      return;
    }

    String? selectedUserId = users.first.id;
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Assign Video to User',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video: ${item.title}', style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
              Text('Language: ${item.languageName}', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: (selectedUserId != null && users.any((u) => u.id == selectedUserId))
                    ? selectedUserId
                    : (users.isNotEmpty ? users.first.id : null),
                dropdownColor: AppTheme.cardBg,
                style: GoogleFonts.outfit(color: AppTheme.lightText),
                decoration: const InputDecoration(
                  labelText: 'Select Target User',
                  prefixIcon: Icon(Icons.person_add, color: AppTheme.primaryPurple),
                ),
                items: users.map((u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Text('${u.fullName} (${u.email})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedUserId = val;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAssigning ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isAssigning
                  ? null
                  : () async {
                      if (selectedUserId == null) return;
                      setDialogState(() => isAssigning = true);

                      final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
                      final success = await assignProv.assignVideoToUser(selectedUserId!, item.id);

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                      if (success && mounted) {
                        assignProv.fetchVideoAssignments(languageId: _selectedLanguageId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Video assigned to user successfully! 🎉'),
                            backgroundColor: AppTheme.neonGreen,
                          ),
                        );
                      } else if (mounted) {
                        final err = assignProv.errorMessage ?? 'Failed to assign video';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $err'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: isAssigning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignProvider = Provider.of<AdminVideoAssignmentsProvider>(context);
    final langProvider = Provider.of<AdminLanguagesProvider>(context);
    final stats = assignProvider.stats;

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Dashboard Stats Cards
            if (stats != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total Videos', '${stats.totalVideos}', Icons.video_library, AppTheme.neonCyan),
                    const SizedBox(width: 10),
                    _buildStatCard('Assigned Videos', '${stats.assignedVideos}', Icons.assignment_turned_in, AppTheme.neonGreen),
                    const SizedBox(width: 10),
                    _buildStatCard('Unassigned', '${stats.unassignedVideos}', Icons.assignment_late_outlined, Colors.amber),
                    const SizedBox(width: 10),
                    _buildStatCard('Active Users Access', '${stats.usersWithAccess}', Icons.group, AppTheme.primaryPink),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Language Filter Bar & Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: AppTheme.lightText),
                      decoration: InputDecoration(
                        hintText: 'Search video by title or description...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.softGrey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.softGrey),
                                onPressed: () {
                                  _searchController.clear();
                                  assignProvider.fetchVideoAssignments(languageId: _selectedLanguageId);
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) {
                        assignProvider.fetchVideoAssignments(languageId: _selectedLanguageId, search: val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Language Folder Choice Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('All Languages'),
                      selected: _selectedLanguageId == null,
                      selectedColor: AppTheme.primaryPurple,
                      backgroundColor: AppTheme.cardBg,
                      labelStyle: GoogleFonts.outfit(
                        color: _selectedLanguageId == null ? Colors.white : AppTheme.lightText,
                        fontWeight: _selectedLanguageId == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedLanguageId = null);
                        assignProvider.fetchVideoAssignments();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...langProvider.languages.map((l) {
                      final isSel = l.id == _selectedLanguageId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(l.name),
                          selected: isSel,
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: AppTheme.cardBg,
                          labelStyle: GoogleFonts.outfit(
                            color: isSel ? Colors.white : AppTheme.lightText,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedLanguageId = l.id);
                              assignProvider.fetchVideoAssignments(languageId: l.id);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10),

            // Video Assignment List Body
            Expanded(
              child: assignProvider.isLoading
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : assignProvider.assignmentItems.isEmpty
                      ? Center(
                          child: Text(
                            'No videos found in this view',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: assignProvider.assignmentItems.length,
                          itemBuilder: (context, index) {
                            final item = assignProvider.assignmentItems[index];
                            return _buildAssignmentCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(VideoAssignmentItem item) {
    Color statusColor = Colors.grey;
    if (item.assignmentStatus == 'LOCKED_BY_SNAPSHOT') {
      statusColor = Colors.amber;
    } else if (item.assignmentStatus == 'ASSIGNED') {
      statusColor = AppTheme.neonGreen;
    }

    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.video_library_outlined, color: AppTheme.neonCyan, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText)),
                      Text('${item.languageName} • ${item.duration}s duration', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Database-backed Assignment Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isSnapshotProtected ? Icons.lock : Icons.assignment_turned_in,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.assignmentLabel,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Snapshot / Assigned counts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_back_outlined, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Snapshot: ${item.snapshotUserCount} user${item.snapshotUserCount == 1 ? '' : 's'}',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 12, color: AppTheme.neonGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned: ${item.activeAccessCount} user${item.activeAccessCount == 1 ? '' : 's'}',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                // Action buttons — use small labels to prevent overflow
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminVideoAssignmentDetailScreen(videoId: item.id),
                      ),
                    );
                    if (result == 'deleted' && context.mounted) {
                      Provider.of<AdminVideoAssignmentsProvider>(context, listen: false)
                          .fetchVideoAssignments(languageId: _selectedLanguageId);
                    }
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14, color: AppTheme.neonCyan),
                  label: Text('Manage Access', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
