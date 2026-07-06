class HierarchyNodeModel {
  final String id;
  final String? parentId;
  final String email;
  final String name;
  final String? avatarUrl;
  final int level;
  final String referralCode;
  final String phoneNumber;
  final String panNumber;
  final String aadharNumber;
  final String whatsApp;
  final String state;
  final String district;
  final int points;
  final List<HierarchyNodeModel> children;

  HierarchyNodeModel({
    required this.id,
    this.parentId,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.level,
    required this.referralCode,
    required this.phoneNumber,
    required this.panNumber,
    required this.aadharNumber,
    required this.whatsApp,
    required this.state,
    required this.district,
    required this.points,
    required this.children,
  });

  factory HierarchyNodeModel.fromJson(Map<String, dynamic> json) {
    final list = json['children'] as List? ?? [];
    final List<HierarchyNodeModel> parsedChildren = list
        .map((childJson) => HierarchyNodeModel.fromJson(childJson))
        .toList();

    return HierarchyNodeModel(
      id: json['id'] ?? '',
      parentId: json['parentId'],
      email: json['email'] ?? '',
      name: json['name'] ?? 'User',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 0,
      referralCode: json['referralCode'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      aadharNumber: json['aadharNumber'] ?? '',
      whatsApp: json['whatsApp'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      points: json['points'] ?? 0,
      children: parsedChildren,
    );
  }
}
