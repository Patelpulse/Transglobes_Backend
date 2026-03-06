import 'package:equatable/equatable.dart';

class AdminProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String profilePhoto;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePhoto = '',
  });

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'admin',
      profilePhoto: map['profilePhoto'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, profilePhoto];
}
