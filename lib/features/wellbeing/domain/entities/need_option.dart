import 'package:equatable/equatable.dart';

/// Una de las cosas que la usuaria puede estar necesitando ahora, en
/// «No sé qué necesito».
class NeedOption extends Equatable {
  final String id;
  final String code;
  final String label;

  const NeedOption({
    required this.id,
    required this.code,
    required this.label,
  });

  @override
  List<Object?> get props => [id, code, label];
}
