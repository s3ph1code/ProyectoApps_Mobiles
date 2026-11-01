import '../../domain/entities/account_status.dart';
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.displayName,
    super.avatarUrl,
    super.bio,
    required super.accountStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      accountStatus: AccountStatus.fromCode(
        (json['account_status'] as String?) ?? AccountStatus.active.code,
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      accountStatus: profile.accountStatus,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'account_status': accountStatus.code,
      };
}
