import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_users_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_languages_provider.dart';
import '../../providers/admin_videos_provider.dart';
import '../../providers/admin_video_assignments_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminUsersProvider>(context, listen: false).fetchUsers(refresh: true);
      Provider.of<AdminLanguagesProvider>(context, listen: false).fetchLanguages();
    });
  }

  void _showAssignLanguageDialog(String userId, String userName) {
    final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
    if (langProvider.languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No language folders available. Please create one in Multilingual Library.')),
      );
      return;
    }

    String selectedLangId = langProvider.languages.first.id;
    String resetOption = 'OPTION_A';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Assign Language for $userName',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select the dedicated video language requested by this user:',
                  style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedLangId,
                  dropdownColor: AppTheme.cardBg,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Assigned Language',
                    prefixIcon: Icon(Icons.language, color: AppTheme.primaryPurple),
                  ),
                  items: langProvider.languages.map((l) {
                    return DropdownMenuItem<String>(
                      value: l.id,
                      child: Text('${l.name} (${l.code})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedLangId = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Warning: If this user has an active video snapshot, changing language may require resetting progress.',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.lightText),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  value: 'OPTION_A',
                  groupValue: resetOption,
                  activeColor: AppTheme.primaryPurple,
                  title: Text('OPTION A: Keep existing snapshot', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText)),
                  onChanged: (v) => setDialogState(() => resetOption = v!),
                ),
                RadioListTile<String>(
                  value: 'OPTION_B',
                  groupValue: resetOption,
                  activeColor: AppTheme.neonCyan,
                  title: Text('OPTION B: Reset snapshot & progress', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                  onChanged: (v) => setDialogState(() => resetOption = v!),
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
              onPressed: () async {
                final videoProvider = Provider.of<AdminVideosProvider>(context, listen: false);
                final success = await videoProvider.assignUserLanguage(userId, selectedLangId);

                if (resetOption == 'OPTION_B') {
                  final usersProvider = Provider.of<AdminUsersProvider>(context, listen: false);
                  await usersProvider.resetUserVideoProgress(userId);
                }

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Assigned language updated for $userName! 🌐'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              },
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSnapshotDetailsDialog(String userId, String userName) async {
    final usersProvider = Provider.of<AdminUsersProvider>(context, listen: false);
    final snapshotData = await usersProvider.fetchUserSnapshot(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Snapshot & Progress: $userName',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: snapshotData == null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No snapshot exists for this user yet. (Snapshot takes effect on user\'s first video hub entry).',
                  style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSnapshotMetricRow('Snapshot Date:', DateFormat('yMMMd HH:mm').format(DateTime.parse(snapshotData['snapshotTakenAt']))),
                    _buildSnapshotMetricRow('Language:', snapshotData['languageName'] ?? 'Default'),
                    _buildSnapshotMetricRow('Snapshot Videos:', '${snapshotData['snapshotVideoCount']} videos'),
                    _buildSnapshotMetricRow('Total Duration:', '${snapshotData['snapshotTotalDurationSeconds']} seconds'),
                    _buildSnapshotMetricRow('Current Progress:', '${snapshotData['currentProgressPercentage']}%'),
                    _buildSnapshotMetricRow(
                      'Refund Eligible:',
                      snapshotData['refundEligible'] ? 'ELIGIBLE' : 'INELIGIBLE',
                      color: snapshotData['refundEligible'] ? AppTheme.neonGreen : Colors.redAccent,
                    ),
                    _buildSnapshotMetricRow('New Videos Unlocked:', snapshotData['newVideosUnlocked'] ? 'YES' : 'NO'),
                    _buildSnapshotMetricRow('Disclaimer Version:', 'v${snapshotData['disclaimerVersion']}'),
                    _buildSnapshotMetricRow(
                      'Accepted Disclaimer:',
                      snapshotData['acceptedDisclaimerAt'] != null
                          ? DateFormat('yMMMd HH:mm').format(DateTime.parse(snapshotData['acceptedDisclaimerAt']))
                          : 'NOT ACCEPTED',
                    ),
                  ],
                ),
              ),
        actions: [
          if (snapshotData != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    title: const Text('Reset Progress & Delete Snapshot?'),
                    content: const Text('This will purge existing video progress and snapshot. A fresh snapshot will be taken when user next enters.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Reset Snapshot'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await usersProvider.resetUserVideoProgress(userId);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User video snapshot & progress reset successfully!'),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset Video Progress'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserVideoAccessDialog(String userId, String userName) async {
    final assignProv = Provider.of<AdminVideoAssignmentsProvider>(context, listen: false);
    final data = await assignProv.fetchUserVideoAccessDetailsAdmin(userId);

    if (!mounted) return;

    final langName = data?['assignedLanguage']?['name'] ?? 'Not Assigned';
    final prodName = data?['assignedProduct']?['name'] ?? 'None';
    final snapshot = data?['snapshotSummary'];
    final List historical = data?['historicalSnapshotVideos'] ?? [];
    final List current = data?['currentAssignments'] ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Video Access: $userName', style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSnapshotMetricRow('Assigned Language:', langName, color: AppTheme.neonCyan),
              _buildSnapshotMetricRow('Assigned Product:', prodName, color: AppTheme.primaryPink),
              const Divider(color: Colors.white10),
              Text('HISTORICAL SNAPSHOT VIDEOS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 4),
              if (snapshot == null)
                Text('No snapshot created yet.', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey))
              else ...[
                Text('${snapshot['snapshotVideoCount']} snapshot videos • ${snapshot['snapshotTotalDurationSeconds']}s total duration', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                const SizedBox(height: 6),
                ...historical.map((hv) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.shield, size: 12, color: Colors.amber),
                          const SizedBox(width: 6),
                          Expanded(child: Text(hv['title'], style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText))),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              Text('CURRENT VIDEO ASSIGNMENTS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
              const SizedBox(height: 4),
              if (current.isEmpty)
                Text('No active extra video assignments.', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey))
              else
                ...current.map((ca) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.neonGreen),
                          const SizedBox(width: 6),
                          Expanded(child: Text(ca['title'], style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText))),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildSnapshotMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color ?? AppTheme.lightText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<AdminUsersProvider>(context, listen: false)
          .loadNextPage(search: _searchController.text.trim());
    }
  }

  void _onSearchChanged() {
    Provider.of<AdminUsersProvider>(context, listen: false)
        .fetchUsers(search: _searchController.text.trim(), refresh: true);
  }

  Future<void> _deleteUser(String id, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to delete user "$email"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final usersProvider = Provider.of<AdminUsersProvider>(context, listen: false);
      final success = await usersProvider.deleteUser(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $email deleted'), backgroundColor: Colors.redAccent),
        );
        if (mounted) {
          Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats(silent: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<AdminUsersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => usersProvider.fetchUsers(search: _searchController.text.trim(), refresh: true),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                style: GoogleFonts.outfit(color: AppTheme.lightText),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.softGrey),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged();
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: usersProvider.isLoading && usersProvider.users.isEmpty
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : usersProvider.users.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => usersProvider.fetchUsers(search: _searchController.text.trim(), refresh: true),
                          color: AppTheme.primaryPurple,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: usersProvider.users.length + (usersProvider.hasNext ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == usersProvider.users.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: SpinKitThreeBounce(
                                      color: AppTheme.primaryPurple,
                                      size: 24,
                                    ),
                                  ),
                                );
                              }

                              final u = usersProvider.users[index];
                              final dateStr = DateFormat('yMMMd').format(DateTime.parse(u.createdAt));
                              final String initials = u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.glassCardDecoration(),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.primaryPurple.withOpacity(0.15),
                                      backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                                      child: u.avatarUrl == null
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                color: AppTheme.primaryPurple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  u.fullName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.lightText,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: u.role == 'ADMIN'
                                                      ? AppTheme.primaryPink.withOpacity(0.15)
                                                      : AppTheme.neonCyan.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  u.role,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: u.role == 'ADMIN' ? AppTheme.primaryPink : AppTheme.neonCyan,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(u.email, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.softGrey)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 12, color: AppTheme.softGrey),
                                              const SizedBox(width: 4),
                                              Text('Joined $dateStr', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey)),
                                              if (u.referralCode.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Text('•  Ref: ${u.referralCode}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonCyan)),
                                              ]
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Balance: ${u.points} PTS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                         IconButton(
                                           icon: const Icon(Icons.analytics_outlined, color: AppTheme.neonCyan),
                                           tooltip: 'View Snapshot & Progress',
                                           onPressed: () => _showUserSnapshotDetailsDialog(u.id, u.fullName),
                                         ),
                                         IconButton(
                                           icon: const Icon(Icons.assignment_ind_outlined, color: AppTheme.neonGreen),
                                           tooltip: 'View Video Access',
                                           onPressed: () => _showUserVideoAccessDialog(u.id, u.fullName),
                                         ),
                                        IconButton(
                                          icon: const Icon(Icons.language, color: AppTheme.primaryPurple),
                                          tooltip: 'Assign Language',
                                          onPressed: () => _showAssignLanguageDialog(u.id, u.fullName),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            u.isActive 
                                                ? Icons.check_circle_outline 
                                                : Icons.block_flipped,
                                            color: u.isActive ? AppTheme.neonGreen : Colors.redAccent,
                                          ),
                                          tooltip: u.isActive ? 'Suspend User' : 'Activate User',
                                          onPressed: () async {
                                             final success = await usersProvider.toggleUserApproval(u.id, !u.isActive);
                                             if (success && context.mounted) {
                                               Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats(silent: true);
                                             }
                                           },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.softGrey),
                                          tooltip: 'Delete User',
                                          onPressed: () => _deleteUser(u.id, u.email),
                                        ),
                                      ],
                                    )
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
