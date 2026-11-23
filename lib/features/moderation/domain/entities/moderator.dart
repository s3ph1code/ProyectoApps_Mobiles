import 'package:equatable/equatable.dart';

/// La cuenta que modera: quién es y que su rol lo permite.
class Moderator extends Equatable {
  final String userId;

  const Moderator({required this.userId});

  @override
  List<Object?> get props => [userId];
}
