class KomandaSession {
  final String token;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String username;
  final String name;
  final String role;

  const KomandaSession({
    required this.token,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.username,
    required this.name,
    required this.role,
  });

  factory KomandaSession.fromLoginResponse(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : const <String, dynamic>{};

    final token = (json['token'] ?? '').toString();
    final restaurantId = (user['restaurantId'] ?? user['restaurant_id'] ?? '').toString();
    if (token.isEmpty || restaurantId.isEmpty) {
      throw const FormatException(
        'El backend no devolvió token o restaurantId.',
      );
    }

    return KomandaSession(
      token: token,
      userId: (user['id'] ?? user['userId'] ?? '').toString(),
      restaurantId: restaurantId,
      restaurantName:
          (user['restaurantName'] ?? user['restaurant_name'] ?? '').toString(),
      username: (user['username'] ?? '').toString(),
      name: (user['name'] ?? user['username'] ?? '').toString(),
      role: (user['role'] ?? 'staff').toString(),
    );
  }

  factory KomandaSession.fromMap(Map<dynamic, dynamic> map) => KomandaSession(
        token: (map['token'] ?? '').toString(),
        userId: (map['userId'] ?? '').toString(),
        restaurantId: (map['restaurantId'] ?? '').toString(),
        restaurantName: (map['restaurantName'] ?? '').toString(),
        username: (map['username'] ?? '').toString(),
        name: (map['name'] ?? map['username'] ?? '').toString(),
        role: (map['role'] ?? 'staff').toString(),
      );

  Map<String, dynamic> toMap() => {
        'token': token,
        'userId': userId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'username': username,
        'name': name,
        'role': role,
      };

  KomandaSession copyWith({
    String? token,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    String? username,
    String? name,
    String? role,
  }) => KomandaSession(
        token: token ?? this.token,
        userId: userId ?? this.userId,
        restaurantId: restaurantId ?? this.restaurantId,
        restaurantName: restaurantName ?? this.restaurantName,
        username: username ?? this.username,
        name: name ?? this.name,
        role: role ?? this.role,
      );

  bool get isValid => token.isNotEmpty && restaurantId.isNotEmpty;
}
