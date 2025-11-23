class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String? profilePic;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePic,
  });
}
