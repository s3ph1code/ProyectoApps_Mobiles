import 'package:equatable/equatable.dart';

class BlockParams extends Equatable {
  final String blockerId;
  final String blockedId;

  const BlockParams({required this.blockerId, required this.blockedId});

  @override
  List<Object?> get props => [blockerId, blockedId];
}
