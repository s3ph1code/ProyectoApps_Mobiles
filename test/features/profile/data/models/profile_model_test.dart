import 'package:doulapp/features/profile/data/models/profile_model.dart';
import 'package:doulapp/features/profile/domain/entities/account_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'id': 'uuid-1',
    'display_name': 'Ana',
    'avatar_url': null,
    'bio': 'Buscando pequeños momentos de calma.',
    'account_status': 'active',
    'created_at': '2026-01-10T08:00:00+00:00',
    'updated_at': '2026-01-11T09:30:00+00:00',
  };

  group('fromJson', () {
    test('mapea las columnas de la tabla profiles', () {
      final model = ProfileModel.fromJson(json);

      expect(model.id, 'uuid-1');
      expect(model.displayName, 'Ana');
      expect(model.avatarUrl, isNull);
      expect(model.bio, 'Buscando pequeños momentos de calma.');
      expect(model.accountStatus, AccountStatus.active);
      expect(model.createdAt, DateTime.utc(2026, 1, 10, 8));
      expect(model.updatedAt, DateTime.utc(2026, 1, 11, 9, 30));
    });

    test('usa active cuando account_status no viene o es desconocido', () {
      expect(
        ProfileModel.fromJson({...json, 'account_status': null}).accountStatus,
        AccountStatus.active,
      );
      expect(
        ProfileModel.fromJson({...json, 'account_status': 'otro'}).accountStatus,
        AccountStatus.active,
      );
    });

    test('reconoce los estados suspended y deactivated', () {
      expect(
        ProfileModel.fromJson({...json, 'account_status': 'suspended'})
            .accountStatus,
        AccountStatus.suspended,
      );
      expect(
        ProfileModel.fromJson({...json, 'account_status': 'deactivated'})
            .accountStatus,
        AccountStatus.deactivated,
      );
    });
  });

  group('toJson', () {
    test('solo incluye los campos que la usuaria puede editar', () {
      final map = ProfileModel.fromJson(json).toJson();

      expect(map, {
        'display_name': 'Ana',
        'avatar_url': null,
        'bio': 'Buscando pequeños momentos de calma.',
      });
    });
  });

  test('fromEntity conserva todos los datos de la entidad', () {
    final model = ProfileModel.fromJson(json);

    expect(ProfileModel.fromEntity(model), model);
  });
}
