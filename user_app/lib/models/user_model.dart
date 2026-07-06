class UserModel {
  final String id;
  final String email;
  final String role;
  final String referralCode;
  final String? referrerId;
  final int points;
  final bool isApproved;
  final String createdAt;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? panNumber;
  final String? aadharNumber;
  final String? whatsApp;
  final String? state;
  final String? district;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.referralCode,
    this.referrerId,
    required this.points,
    required this.isApproved,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.panNumber,
    this.aadharNumber,
    this.whatsApp,
    this.state,
    this.district,
  });

  String get fullName {
    if (firstName == null && lastName == null) return 'Referral User';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Check if profile details are nested inside 'profile' key
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      referralCode: json['referralCode'] ?? '',
      referrerId: json['referrerId'],
      points: json['points'] ?? 0,
      isApproved: json['isApproved'] ?? true,
      createdAt: json['createdAt'] ?? '',
      firstName: profile != null ? profile['firstName'] : json['firstName'],
      lastName: profile != null ? profile['lastName'] : json['lastName'],
      phoneNumber: profile != null ? profile['phoneNumber'] : json['phoneNumber'],
      avatarUrl: profile != null ? profile['avatarUrl'] : json['avatarUrl'],
      bio: profile != null ? profile['bio'] : json['bio'],
      panNumber: profile != null ? profile['panNumber'] : json['panNumber'],
      aadharNumber: profile != null ? profile['aadharNumber'] : json['aadharNumber'],
      whatsApp: profile != null ? profile['whatsApp'] : json['whatsApp'],
      state: profile != null ? profile['state'] : json['state'],
      district: profile != null ? profile['district'] : json['district'],
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
      'createdAt': createdAt,
      'profile': {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'panNumber': panNumber,
        'aadharNumber': aadharNumber,
        'whatsApp': whatsApp,
        'state': state,
        'district': district,
      }
    };
  }
}
