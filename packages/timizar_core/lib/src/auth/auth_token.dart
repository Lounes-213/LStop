class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final DateTime issuedAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt ?? DateTime.now();

  bool get isExpired {
    final expiresAt = issuedAt.add(Duration(seconds: expiresInSeconds - 30)); // 30s buffer
    return DateTime.now().isAfter(expiresAt);
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 900,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': expiresInSeconds,
  };
}
