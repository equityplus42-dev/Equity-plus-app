class HierarchyNodeModel {
  final String id;
  final String? parentId;
  final String email;
  final String name;
  final String? avatarUrl;
  final int level;
  final List<HierarchyNodeModel> children;

  HierarchyNodeModel({
    required this.id,
    this.parentId,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.level,
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
      children: parsedChildren,
    );
  }
}
