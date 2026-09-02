/// Represents a user in the MindCare system.
enum UserRole { patient, psychologist }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? psychologistId; // If role == psychologist, links to their profile

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.psychologistId,
  });
}
