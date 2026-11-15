/// Data akun mahasiswa. Password tidak pernah disimpan dalam bentuk asli,
/// hanya hash + salt.
class AppUser {
  const AppUser({
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.fullName,
    required this.programStudi,
    required this.semester,
    this.nim = '',
  });

  final String email;
  final String passwordHash;
  final String salt;
  final String fullName;
  final String programStudi;
  final String semester;
  final String nim;

  String get initial {
    final name = fullName.trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        email: json['email']?.toString() ?? '',
        passwordHash: json['passwordHash']?.toString() ?? '',
        salt: json['salt']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        programStudi: json['programStudi']?.toString() ?? '',
        semester: json['semester']?.toString() ?? '',
        nim: json['nim']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'fullName': fullName,
        'programStudi': programStudi,
        'semester': semester,
        'nim': nim,
      };

  AppUser copyWith({
    String? fullName,
    String? programStudi,
    String? semester,
    String? nim,
  }) =>
      AppUser(
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        fullName: fullName ?? this.fullName,
        programStudi: programStudi ?? this.programStudi,
        semester: semester ?? this.semester,
        nim: nim ?? this.nim,
      );
}
