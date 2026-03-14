class AuthModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;
  final User user;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json["access_token"],
      refreshToken: json["refresh_token"],
      tokenType: json["token_type"],
      expiresIn: json["expires_in"],
      user: User.fromJson(json["user"]),
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? agenceId;
  final String? agenceNom;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.agenceId,
    this.agenceNom,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      fullName: json["full_name"],
      email: json["email"],
      phone: json["phone"],
      role: json["role"],
      agenceId: json["agence_id"],
      agenceNom: json["agence_nom"],
    );
  }
}
