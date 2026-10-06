class User {
  final String id;
  final String email;
  final String username;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  bool get isAdmin =>
      role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'EXAMINER';
  bool get isStudent =>
      role.toUpperCase() == 'STUDENT' || role.toUpperCase() == 'CLIENT';

  String get displayName =>
      username.isNotEmpty ? username : (email.isNotEmpty ? email : 'User');

  factory User.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] ?? 'STUDENT').toString().toUpperCase();
    final emailStr = (json['email'] ?? '').toString();
    final usernameStr = (json['username'] ?? '').toString();

    return User(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? '').toString(),
      email: emailStr.isNotEmpty ? emailStr : usernameStr,
      username: usernameStr.isNotEmpty ? usernameStr : emailStr,
      role: roleStr,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'role': role,
  };
}
