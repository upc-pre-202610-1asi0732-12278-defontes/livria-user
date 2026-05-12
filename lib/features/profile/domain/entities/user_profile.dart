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
      subscription: map['subscription'] ?? 'freeplan',
      planChangeDate: map['planChangeDate'] != null
          ? DateTime.tryParse(map['planChangeDate'].toString())
          : null,
      hasPayed: map['hasPayed'] ?? false,
    );
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