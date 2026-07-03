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
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final referee = json['referee'] as Map<String, dynamic>?;
    final refereeProfile = referee != null ? referee['profile'] as Map<String, dynamic>? : null;

    String parsedName = 'Referee User';
    if (refereeProfile != null) {
      final String first = refereeProfile['firstName'] ?? '';
      final String last = refereeProfile['lastName'] ?? '';
      parsedName = '$first $last'.trim();
      if (parsedName.isEmpty) parsedName = 'Referee User';
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
      refereeName: parsedName,
      refereeAvatarUrl: refereeProfile != null ? refereeProfile['avatarUrl'] : null,
    );
  }
}
