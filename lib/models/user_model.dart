class UserModel {
  final int id;
  final String name;
  final String email;
  final String? noHp;
  final String role; // 'guru', 'ortu', 'admin'
  final String? nip;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.noHp,
    required this.role,
    this.nip,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      noHp: json['no_hp'] as String?,
      role: json['role'] as String? ?? 'guru',
      nip: json['nip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'no_hp': noHp,
      'role': role,
      'nip': nip,
    };
  }
}
