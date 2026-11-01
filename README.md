# Doulapp

App móvil Flutter de acompañamiento posparto. Proyecto académico, Universidad Icesi.

> «Tu bienestar también importa.»

La documentación del producto, el modelo de datos y la arquitectura están en [`docs/`](docs/).
El alcance de la entrega en curso está en [`docs/05-entrega-actual.md`](docs/05-entrega-actual.md).

## Requisitos

- Flutter 3.44 o superior (Dart 3.12)
- Una cuenta de [Supabase](https://supabase.com)

## Puesta en marcha

```bash
flutter pub get
cp .env.example .env    # en Windows: copy .env.example .env
```

Completa `.env` con los datos del proyecto de Supabase:

```
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_ANON_KEY=<clave pública del proyecto>
```

Ambos valores están en el panel de Supabase, en **Project Settings → API**.
`SUPABASE_ANON_KEY` es la clave pública (Supabase la llama *anon key* o
*publishable key*): es segura en el cliente, al contrario que la *service role key*,
que nunca debe salir del servidor.

`.env` está en `.gitignore`. Cada integrante crea el suyo a partir de `.env.example`.

```bash
flutter run
```

## Configuración de Supabase

1. Crear un proyecto en Supabase.
2. Abrir **SQL Editor** y ejecutar [`supabase/migrations/0001_identity.sql`](supabase/migrations/0001_identity.sql).
   Es el bloque de identidad de [`supabase/schema.sql`](supabase/schema.sql): crea
   `roles`, `profiles`, `user_preferences`, `user_roles`, los triggers y las
   políticas de RLS. El resto del esquema se ejecuta cuando entren en alcance
   sus módulos.
3. En **Authentication → Providers**, dejar *Email* habilitado.
4. Para probar el registro sin revisar el correo, desactivar **Confirm email**
   en **Authentication → Sign In / Providers → Email**. Si se deja activo, el
   `signIn` devolverá el mensaje «Falta confirmar tu correo» hasta que la
   usuaria abra el enlace.

El trigger `handle_new_user` crea la fila de `profiles`, `user_preferences` y
`user_roles` en cuanto Supabase registra al usuario, para que no exista una
cuenta autenticada sin perfil.

## Arquitectura

Clean Architecture por feature, BLoC en presentación y Supabase como backend.
Las convenciones completas están en [`docs/04-arquitectura-flutter.md`](docs/04-arquitectura-flutter.md).

```
lib/
├── main.dart
├── injection_container.dart
├── core/            config · error · usecase · theme
└── features/
    ├── auth/        registro, login, logout
    ├── profile/     entidad Profile y su repositorio
    └── onboarding/  captura de datos iniciales
```

La regla de dependencias es `presentation → domain ← data`. `domain` no importa
Supabase ni Flutter. Los errores viajan como `Either<Failure, T>`: la UI nunca
ve una excepción cruda.

## Pruebas

```bash
flutter test
flutter analyze
```

## Notas para el equipo

**El perfil ya existe cuando termina el registro.** El trigger
`handle_new_user` inserta la fila de `profiles` con un nombre provisional
tomado de la parte local del correo. Por eso `ProfileRepository.createProfile`
debe escribirse como un `update` (o un `upsert`) sobre la fila existente, no
como un `insert`: `profiles` solo tiene políticas de RLS de `select` y `update`,
así que un `insert` desde el cliente sería rechazado.

**`user_preferences` se crea sola.** El mismo trigger la inserta con los valores
por defecto (`community`, notificaciones activas, `es`). El onboarding solo
necesita actualizarla.

**Ruta del SDK con espacios.** `pubspec.yaml` fija
`path_provider_foundation: 2.4.1` mediante `dependency_overrides`. Las versiones
más nuevas arrastran `objective_c`, cuyo hook de *native assets* falla si la
ruta del SDK de Flutter contiene espacios (por ejemplo
`C:\Users\Nombre Apellido\flutter`). Si tu SDK está en una ruta sin espacios,
puedes quitar ese bloque.
