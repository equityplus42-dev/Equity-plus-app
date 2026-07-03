class UserModel {
  final String id;
  final String email;
  final String role;
  final String referralCode;
  final String? referrerId;
  final int points;
  final bool isApproved;
  final bool isActive;
  final String createdAt;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.referralCode,
    this.referrerId,
    required this.points,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
  });

  String get fullName {
    if (firstName == null && lastName == null) return 'Referral User';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      referralCode: json['referralCode'] ?? '',
      referrerId: json['referrerId'],
      points: json['points'] ?? 0,
      isApproved: json['isApproved'] ?? true,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      firstName: profile != null ? profile['firstName'] : json['firstName'],
      lastName: profile != null ? profile['lastName'] : json['lastName'],
      phoneNumber: profile != null ? profile['phoneNumber'] : json['phoneNumber'],
      avatarUrl: profile != null ? profile['avatarUrl'] : json['avatarUrl'],
      bio: profile != null ? profile['bio'] : json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'referralCode': referralCode,
      'referrerId': referrerId,
      'points': points,
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': createdAt,
      'profile': {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'bio': bio,
      }
    };
  }
}
