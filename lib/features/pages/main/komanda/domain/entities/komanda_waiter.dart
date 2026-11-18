class KomandaWaiter {
  final String id;
  final String userId;
  final String name;
  final String username;
  final String password;
  final bool active;

  const KomandaWaiter({
    required this.id,
    required this.name,
    this.userId = '',
    this.username = '',
    this.password = '',
    this.active = true,
  });

  KomandaWaiter copyWith({
    String? id,
    String? userId,
    String? name,
    String? username,
    String? password,
    bool? active,
  }) {
    return KomandaWaiter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      active: active ?? this.active,
    );
  }
}
