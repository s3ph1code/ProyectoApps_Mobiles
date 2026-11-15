import '../../domain/entities/need_option.dart';

class NeedOptionModel extends NeedOption {
  const NeedOptionModel({
    required super.id,
    required super.code,
    required super.label,
  });

  factory NeedOptionModel.fromJson(Map<String, dynamic> json) {
    return NeedOptionModel(
      id: json['id'] as String,
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }
}
