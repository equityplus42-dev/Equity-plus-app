import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/referral_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReferralProvider>(context, listen: false).fetchReferrals();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppTheme.neonGreen;
      case 'PENDING':
        return Colors.amberAccent;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return AppTheme.softGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralProvider = Provider.of<ReferralProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Referrals'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: referralProvider.isLoading
            ? const Center(
                child: SpinKitPulse(
                  color: AppTheme.primaryPurple,
                  size: 50.0,
                ),
              )
            : referralProvider.referrals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No Referrals Yet',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Invites that sign up using your referral code will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppTheme.softGrey),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => referralProvider.fetchReferrals(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: referralProvider.referrals.length,
                      itemBuilder: (context, index) {
                        final ref = referralProvider.referrals[index];
                        final String dateStr = DateFormat('yMMMd').format(ref.createdAt);
                        final String firstChar = ref.refereeName.isNotEmpty ? ref.refereeName[0].toUpperCase() : 'U';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
                                backgroundImage: ref.refereeAvatarUrl != null
                                    ? NetworkImage(ref.refereeAvatarUrl!)
                                    : null,
                                child: ref.refereeAvatarUrl == null
                                    ? Text(
                                        firstChar,
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
                                    Text(
                                      ref.refereeName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ref.refereeEmail,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.softGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Signed up on: $dateStr',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppTheme.softGrey.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(ref.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(ref.status).withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      ref.status,
                                      style: TextStyle(
                                        color: _getStatusColor(ref.status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '+${ref.points} PTS',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: ref.status == 'APPROVED' 
                                          ? AppTheme.neonGreen 
                                          : AppTheme.softGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
