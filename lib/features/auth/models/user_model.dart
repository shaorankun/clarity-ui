class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:          json['id'],
    email:       json['email'],
    displayName: json['displayName'],
    avatarUrl:   json['avatarUrl'],
  );
}