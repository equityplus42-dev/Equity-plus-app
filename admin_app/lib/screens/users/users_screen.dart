import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_users_provider.dart';
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
    });
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
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete user $email? All their downline relationships and referrals will be modified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          )
        ],
      )
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<AdminUsersProvider>(context, listen: false).deleteUser(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully.'), backgroundColor: AppTheme.neonGreen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<AdminUsersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Search input
              TextField(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, or code...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.softGrey),
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
              const SizedBox(height: 20),

              // Users list
              Expanded(
                child: usersProvider.users.isEmpty && usersProvider.isLoading
                    ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                    : usersProvider.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 80, color: AppTheme.softGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'No Users Found',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightText,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => usersProvider.fetchUsers(
                              search: _searchController.text.trim(),
                              refresh: true,
                            ),
                            color: AppTheme.primaryPurple,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
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
                                      const SizedBox(width: 16),
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
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryPurple.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    u.referralCode,
                                                    style: const TextStyle(
                                                      color: AppTheme.primaryPurple,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(u.email, style: const TextStyle(fontSize: 12, color: AppTheme.softGrey)),
                                            const SizedBox(height: 2),
                                            Text('Joined: $dateStr', style: TextStyle(fontSize: 10, color: AppTheme.softGrey.withOpacity(0.6))),
                                            const SizedBox(height: 4),
                                            Text('Balance: ${u.points} PTS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              u.isApproved 
                                                  ? Icons.check_circle_outline 
                                                  : Icons.block_flipped,
                                              color: u.isApproved ? AppTheme.neonGreen : Colors.redAccent,
                                            ),
                                            tooltip: u.isApproved ? 'Suspend User' : 'Approve User',
                                            onPressed: () => usersProvider.toggleUserApproval(u.id, !u.isApproved),
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
      ),
    );
  }
}
