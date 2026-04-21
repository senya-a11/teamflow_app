class User {
  final int id;
  final String username;
  final String role;
  final String? createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      createdAt: json['created_at'],
    );
  }

  bool get isTeamLeader => role == 'team_leader';
  bool get isCrew => role == 'crew';
}
