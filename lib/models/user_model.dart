import 'dart:typed_data';

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.isPhoneVerified = true,
    this.avatarBytes,
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isPhoneVerified;
  final Uint8List? avatarBytes;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NS';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    bool? isPhoneVerified,
    Uint8List? avatarBytes,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      avatarBytes: avatarBytes ?? this.avatarBytes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'isPhoneVerified': isPhoneVerified,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '+237 6 70 12 34 56',
      isPhoneVerified: (json['isPhoneVerified'] as bool?) ?? true,
    );
  }
}
