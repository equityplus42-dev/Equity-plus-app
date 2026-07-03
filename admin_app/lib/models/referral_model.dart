class ReferralModel {
  final String id;
  final String referrerId;
  final String refereeId;
  final String status;
  final int points;
  final DateTime createdAt;
  
  // Nested referee details
  final String refereeEmail;
  final String refereeName;
  final String? refereeAvatarUrl;

  // Nested referrer details (Admin specific)
  final String? referrerEmail;
  final String? referrerName;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.status,
    required this.points,
    required this.createdAt,
    required this.refereeEmail,
    required this.refereeName,
    this.refereeAvatarUrl,
    this.referrerEmail,
    this.referrerName,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final referee = json['referee'] as Map<String, dynamic>?;
    final refereeProfile = referee != null ? referee['profile'] as Map<String, dynamic>? : null;

    final referrer = json['referrer'] as Map<String, dynamic>?;
    final referrerProfile = referrer != null ? referrer['profile'] as Map<String, dynamic>? : null;

    String parsedRefereeName = 'Referee User';
    if (refereeProfile != null) {
      final String first = refereeProfile['firstName'] ?? '';
      final String last = refereeProfile['lastName'] ?? '';
      parsedRefereeName = '$first $last'.trim();
      if (parsedRefereeName.isEmpty) parsedRefereeName = 'Referee User';
    }

    String? parsedReferrerName;
    if (referrerProfile != null) {
      final String first = referrerProfile['firstName'] ?? '';
      final String last = referrerProfile['lastName'] ?? '';
      parsedReferrerName = '$first $last'.trim();
      if (parsedReferrerName.isEmpty) parsedReferrerName = referrer?['email'];
    }

    return ReferralModel(
      id: json['id'] ?? '',
      referrerId: json['referrerId'] ?? '',
      refereeId: json['refereeId'] ?? '',
      status: json['status'] ?? 'PENDING',
      points: json['points'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      refereeEmail: referee != null ? referee['email'] ?? '' : '',
      refereeName: parsedRefereeName,
      refereeAvatarUrl: refereeProfile != null ? refereeProfile['avatarUrl'] : null,
      referrerEmail: referrer != null ? referrer['email'] : null,
      referrerName: parsedReferrerName,
    );
  }
}
