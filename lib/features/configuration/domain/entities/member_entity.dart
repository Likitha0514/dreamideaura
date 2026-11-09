
class MemberEntity {
  const MemberEntity({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
}
