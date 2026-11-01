# 05 · Entrega actual

## Alcance

Solo esto. El modelo de datos de `docs/03-modelo-de-datos.md` describe la app completa, pero **esta entrega cubre únicamente identidad y perfil**.

**Dentro de alcance**

- Registro con correo y contraseña, contra Supabase Auth
- Inicio de sesión
- Cierre de sesión, si hace falta para probar el flujo
- Onboarding mínimo que recoge los datos iniciales del perfil
- Pantalla de resumen del perfil
- Navegación entre registro, login y perfil
- Manejo de estados de carga, éxito y error

**Fuera de alcance**

Microdescansos · Comunidad · Bienestar emocional · «No sé qué necesito» · Notificaciones · Moderación · Roles

No crees carpetas ni tablas de esos módulos.

## Tablas que se implementan

De las 25 del modelo, en esta entrega solo se crean tres:

| Tabla | Para qué |
|---|---|
| `profiles` | Datos del perfil, 1:1 con `auth.users` |
| `user_preferences` | Preferencias recogidas en el onboarding |
| `auth.users` | **No se crea.** La gestiona Supabase |

Si el onboarding no recoge preferencias, `user_preferences` también puede quedar fuera. Decídelo antes de empezar y déjalo escrito.

## Features Flutter que se crean

```
lib/features/
├── auth/        # registro, login, logout
├── profile/     # entidad Profile, repositorio, pantalla de resumen
└── onboarding/  # captura de datos iniciales
```

## División del equipo

### Integrante 1 — Autenticación y Supabase
*Infraestructura y datos*

Conectar la aplicación con el servicio de autenticación.

- Configurar Supabase y sus variables de entorno
- Implementar los DataSources de autenticación
- Implementar `AuthRepository` y su implementación
- Gestionar registro, inicio de sesión y cierre de sesión si se necesita para probar el flujo
- Manejar errores de credenciales y registro

**Entregable:** autenticación funcional conectada a Supabase.

### Integrante 2 — Perfil y onboarding
*Dominio y persistencia del perfil*

Definir y gestionar los datos iniciales del usuario.

- Definir las entidades `AuthUser` y `Profile`, según corresponda
- Diseñar la tabla `profiles` y sus relaciones con el usuario autenticado
- Implementar `ProfileRepository`, su DataSource y su implementación
- Crear el caso de uso que registra el perfil después de crear la cuenta
- Recuperar los datos para el resumen del perfil

**Entregable:** datos iniciales guardados y perfil recuperable.

### Integrante 3 — Interfaz y BLoC
*Presentación*

Construir las pantallas y conectar sus estados con la lógica de la aplicación.

- Diseñar la pantalla de registro y el onboarding mínimo
- Crear la pantalla de inicio de sesión
- Implementar `RegisterBloc` y `LoginBloc`, coordinándose con los casos de uso
- Gestionar estados de carga, éxito y error
- Validar los formularios y mostrar mensajes comprensibles

**Entregable:** formularios funcionales conectados a los BLoC.

### Integrante 4 — Integración, perfil visual y entrega
*Integración y calidad*

Asegurar que el flujo completo funcione y que la entrega cumpla los requisitos.

- Crear la pantalla de resumen del perfil
- Configurar rutas y navegación entre registro, login y perfil
- Integrar las dependencias mediante `BlocProvider` y la inyección correspondiente
- Probar los flujos completos y los casos de error
- Preparar el README, coordinar el video de máximo 2 minutos y verificar el commit etiquetado

**Entregable:** flujo integrado, probado y listo para presentar.

## Contratos entre integrantes

Para que los cuatro puedan trabajar en paralelo sin bloquearse, estas interfaces se definen **primero** y no se cambian sin avisar:

```dart
// domain/entities/auth_user.dart        — Integrante 2
class AuthUser {
  final String id;
  final String email;
}

// domain/entities/profile.dart          — Integrante 2
class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// domain/repositories/auth_repository.dart     — Integrante 1
abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signUp({required String email, required String password});
  Future<Either<Failure, AuthUser>> signIn({required String email, required String password});
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, AuthUser?>> getCurrentUser();
}

// domain/repositories/profile_repository.dart  — Integrante 2
abstract class ProfileRepository {
  Future<Either<Failure, Profile>> createProfile({required String userId, required String displayName});
  Future<Either<Failure, Profile>> getProfile(String userId);
  Future<Either<Failure, Profile>> updateProfile(Profile profile);
}
```

El Integrante 3 programa contra estas interfaces aunque todavía no existan las implementaciones: usa `mocktail` para no quedarse esperando.

## Orden de trabajo sugerido

1. **Juntos:** crear el proyecto, el `pubspec.yaml`, la estructura de carpetas y los contratos de arriba. Commit inicial.
2. **Integrante 1** levanta Supabase y ejecuta `supabase/schema.sql` (solo la parte de identidad).
3. **1 y 2 en paralelo:** auth y perfil, cada uno en su feature.
4. **Integrante 3** arranca en paralelo con mocks de los repositorios.
5. **Integrante 4** conecta todo cuando 1, 2 y 3 tengan algo funcional.

## Checklist de entrega

- [ ] El flujo registro → onboarding → perfil funciona de principio a fin
- [ ] El login con una cuenta existente funciona
- [ ] Los errores de credenciales muestran un mensaje comprensible en español
- [ ] `.env` está en `.gitignore` y existe `.env.example`
- [ ] `flutter analyze` pasa sin advertencias
- [ ] README con pasos de instalación y configuración de Supabase
- [ ] Video de máximo 2 minutos
- [ ] Commit etiquetado
