import 'package:equatable/equatable.dart';

/// La cuenta que administra: quién es y que su rol lo permite.
class Administrator extends Equatable {
  final String userId;

  const Administrator({required this.userId});

  @override
  List<Object?> get props => [userId];
}
