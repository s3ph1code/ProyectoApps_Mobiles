import 'package:doulapp/features/profile/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRole', () {
    test('fromCode reconoce los códigos de la tabla roles', () {
      expect(AppRole.fromCode('user'), AppRole.user);
      expect(AppRole.fromCode('moderator'), AppRole.moderator);
      expect(AppRole.fromCode('admin'), AppRole.admin);
    });

    test('fromCode devuelve null para un código desconocido', () {
      expect(AppRole.fromCode('superuser'), isNull);
    });

    test('cada rol tiene su nombre en español', () {
      expect(AppRole.user.label, 'Usuaria');
      expect(AppRole.moderator.label, 'Moderadora');
      expect(AppRole.admin.label, 'Administradora');
    });

    test('los permisos crecen con la jerarquía del rol', () {
      expect(AppRole.user.canModerate, isFalse);
      expect(AppRole.user.canAdminister, isFalse);
      expect(AppRole.moderator.canModerate, isTrue);
      expect(AppRole.moderator.canAdminister, isFalse);
      expect(AppRole.admin.canModerate, isTrue);
      expect(AppRole.admin.canAdminister, isTrue);
    });
  });

  group('AppRoles', () {
    test('primary devuelve el rol de mayor jerarquía', () {
      expect([AppRole.user].primary, AppRole.user);
      expect([AppRole.user, AppRole.moderator].primary, AppRole.moderator);
      expect(
        [AppRole.admin, AppRole.user, AppRole.moderator].primary,
        AppRole.admin,
      );
    });

    test('primary es null cuando no hay roles', () {
      expect(<AppRole>[].primary, isNull);
    });

    test('los permisos de una cuenta suman los de todos sus roles', () {
      expect([AppRole.user].canModerate, isFalse);
      expect([AppRole.user, AppRole.moderator].canModerate, isTrue);
      expect([AppRole.user, AppRole.moderator].canAdminister, isFalse);
      expect([AppRole.user, AppRole.admin].canAdminister, isTrue);
    });
  });
}
