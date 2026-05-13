class UserProfile {
  final int id;
  final String display;
  final String username;
  final String email;
  final String icon;
  final String phrase;
  final String subscription;
  final DateTime? planChangeDate;
  final bool hasPayed;

  const UserProfile({
    required this.id,
    required this.display,
    required this.username,
    required this.email,
    required this.icon,
    required this.phrase,
    required this.subscription,
    this.planChangeDate,
    this.hasPayed = false,
  });

  factory UserProfile.empty() {
    return const UserProfile(
      id: 0,
      display: '',
      username: '',
      email: '',
      icon: '',
      phrase: '',
      subscription: 'freeplan',
      hasPayed: false,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? 0,
      display: map['display'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      icon: map['icon'] ?? '',
      phrase: map['phrase'] ?? '',
      subscription: (map['subscription'] ?? map['Subscription'] ?? 'freeplan').toString(),
      planChangeDate: _parseDateTime(map['planChangeDate'] ?? map['PlanChangeDate']),
      hasPayed: _parseBool(map['hasPayed'] ?? map['HasPayed']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Acepta camelCase (JSON por defecto en .NET) y PascalCase por si el API cambia.
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'display': display,
      'username': username,
      'email': email,
      'icon': icon,
      'phrase': phrase,
    };
  }

  UserProfile copyWith({
    String? display,
    String? username,
    String? email,
    String? icon,
    String? phrase,
    String? subscription,
    DateTime? planChangeDate,
    bool? hasPayed,
  }) {
    return UserProfile(
      id: id,
      display: display ?? this.display,
      username: username ?? this.username,
      email: email ?? this.email,
      icon: icon ?? this.icon,
      phrase: phrase ?? this.phrase,
      subscription: subscription ?? this.subscription,
      planChangeDate: planChangeDate ?? this.planChangeDate,
      hasPayed: hasPayed ?? this.hasPayed,
    );
  }
}