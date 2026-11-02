# Doulapp

App móvil Flutter de acompañamiento posparto. Proyecto académico, Universidad Icesi.

> «Tu bienestar también importa.»

La app acompaña a la persona que cuida, no al bebé. El tono del producto es parte
del requisito: lenguaje sin culpa, sin metas ni rachas, una sola decisión por
pantalla y acciones principales en el tercio inferior, para usarla con una mano.

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
*publishable key*): es segura en el cliente, al contrario que la *service role
key*, que nunca debe salir del servidor.

`.env` está en `.gitignore`. Cada integrante crea el suyo a partir de
`.env.example`.

```bash
flutter run
```

## Configuración de Supabase

1. Crear un proyecto en Supabase.
2. Abrir **SQL Editor** y ejecutar
   [`supabase/migrations/0001_identity.sql`](supabase/migrations/0001_identity.sql).
   Crea `roles`, `profiles`, `user_preferences`, `user_roles`, los triggers y las
   políticas de RLS.
3. En **Authentication → Providers**, dejar *Email* habilitado.
4. Para probar el registro sin revisar el correo, desactivar **Confirm email**
   en **Authentication → Sign In / Providers → Email**. Si se deja activo, el
   inicio de sesión responderá «Falta confirmar tu correo» hasta que la usuaria
   abra el enlace.

[`supabase/schema.sql`](supabase/schema.sql) contiene el esquema completo de la
app (25 tablas en 5 módulos). Solo el bloque de identidad entra en la entrega
actual; el resto se ejecuta cuando sus módulos entren en alcance.

La identidad la gestiona **Supabase Auth**: no hay tablas de contraseñas ni de
identidades de proveedor. `public.profiles` cuelga de `auth.users` y comparte su
`id`. El trigger `handle_new_user` crea la fila de `profiles`,
`user_preferences` y `user_roles` en cuanto Supabase registra al usuario, para
que no exista una cuenta autenticada sin perfil.

## Arquitectura

Clean Architecture por feature, BLoC en presentación y Supabase como backend.

```
lib/
├── main.dart
├── injection_container.dart          # registro de get_it
│
├── core/
│   ├── config/supabase_config.dart   # init del cliente, lee .env
│   ├── error/                        # exceptions.dart y failures.dart
│   ├── router/app_router.dart        # rutas con GoRouter y provisión de BLoC
│   ├── usecase/usecase.dart          # UseCase<T, Params>
│   └── theme/                        # colores, tipografía, radios, tema
│
└── features/
    ├── auth/                         # registro, login, logout, recuperar acceso, sesión
    ├── profile/                      # entidad Profile, repositorio, ProfileBloc y ProfilePage
    ├── onboarding/                   # carrusel de bienvenida
    ├── home/                         # inicio
    └── splash/                       # pantalla de bienvenida
```

### Rutas y navegación

Configuradas en `lib/core/router/app_router.dart` con `GoRouter`. Un
`SessionNotifier` escucha los cambios de sesión de Supabase y el router
redirige: sin sesión solo se ven las rutas públicas; con sesión, entrar a
`/login` lleva al resumen del perfil.

| Ruta | Acceso | Propósito |
|---|---|---|
| `/splash` | público | Pantalla de bienvenida de la marca |
| `/login` | público | Inicio de sesión → `/profile` |
| `/register` | público | Cuenta nueva (nombre, correo, contraseña, términos) → `/onboarding` |
| `/forgot-password` | público | Envía el enlace para recuperar el acceso |
| `/onboarding` | privado | Carrusel informativo de tres pasos → `/profile` |
| `/home` | privado | Inicio con las seis secciones (las que aún no existen abren «Próximamente») |
| `/for-me`, `/support` | privado | Pestañas «Para mí» y «Apoyo» (próximamente) |
| `/profile` | privado | Resumen del perfil: nombre, rol, correo, privacidad y cierre de sesión |

La barra inferior tiene cuatro pestañas: Inicio, Para mí, Apoyo y Perfil.

### Recorrido para probar el flujo

1. Abrir la app y pulsar **Crear cuenta**. Escribir nombre, correo, contraseña
   (dos veces) y aceptar los términos.
2. Pasar el carrusel de bienvenida (o **Omitir**). Se llega al **resumen del
   perfil** con el nombre escrito y el rol «Usuaria».
3. Pulsar **Cerrar sesión**; se vuelve al inicio de sesión.
4. Iniciar sesión con la misma cuenta: se llega de nuevo al resumen del perfil.
5. En el inicio de sesión, **¿Olvidaste tu contraseña?** abre la pantalla de
   recuperación.

### Roles

Hay tres roles: **usuaria**, **moderadora** y **administradora**. Toda cuenta
nueva nace como usuaria (lo asigna el trigger `handle_new_user`). Para probar
los otros dos:

1. Crear desde la app las cuentas `moderadora@doulapp.test` y
   `admin@doulapp.test`.
2. Ejecutar [`supabase/seed_demo_roles.sql`](supabase/seed_demo_roles.sql) en el
   **SQL Editor**; asigna el rol correspondiente y termina con una consulta de
   verificación.

El rol aparece como una etiqueta en el resumen del perfil.

### Recorrido por cada usuaria (para el video)

| Cuenta | Cómo se obtiene | Qué se ve al iniciar sesión |
|---|---|---|
| Usuaria (cualquier correo) | Registro normal desde la app | Resumen del perfil con la etiqueta «Usuaria» |
| `moderadora@doulapp.test` | Registro + `seed_demo_roles.sql` | Resumen del perfil con la etiqueta «Moderadora» |
| `admin@doulapp.test` | Registro + `seed_demo_roles.sql` | Resumen del perfil con la etiqueta «Administradora» |

En las tres, el flujo es el mismo: **Crear cuenta → carrusel → resumen del
perfil → Cerrar sesión → Iniciar sesión → resumen del perfil**. Para probar sin
revisar el correo, desactivar «Confirm email» en Supabase.

Cada feature se divide en `data/` (datasources, models, repositories),
`domain/` (entities, repositories, usecases) y `presentation/` (bloc, pages,
widgets).

**Regla de dependencias:** `presentation → domain ← data`.
`domain` no importa `supabase_flutter` ni `flutter`: solo entidades, interfaces
de repositorio y casos de uso. `data` es el único lugar donde aparece Supabase.
`presentation` llega al dominio a través de los casos de uso, nunca a un
DataSource.

**Errores:**

```
DataSource lanza Exception → Repository devuelve Left(Failure) → BLoC emite
estado de error → la UI muestra el mensaje
```

El mensaje en español vive en el `Failure`: explica qué pasó y qué hacer, sin
tecnicismos y sin disculpas. La presentación nunca ve una excepción cruda.

### Convenciones

Código, identificadores y nombres de archivo en inglés; textos de interfaz en
español. Tablas y columnas en `snake_case`, clases Dart en `PascalCase`.

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivo | `snake_case.dart` | `auth_remote_datasource.dart` |
| Entidad | `PascalCase`, singular | `Profile` |
| Modelo | entidad + `Model` | `ProfileModel` |
| Interfaz de repositorio | entidad + `Repository` | `AuthRepository` |
| Implementación | interfaz + `Impl` | `AuthRepositoryImpl` |
| DataSource | entidad + `RemoteDataSource` | `AuthRemoteDataSource` |
| Caso de uso | verbo en infinitivo | `SignInWithEmail` |
| BLoC | contexto + `Bloc` | `LoginBloc` |

### Contratos compartidos

Estas interfaces se definen primero y no se cambian sin avisar al equipo, para
que los cuatro puedan trabajar en paralelo:

- `features/auth/domain/entities/auth_user.dart` — `AuthUser`
- `features/profile/domain/entities/profile.dart` — `Profile`
- `features/auth/domain/repositories/auth_repository.dart` — `AuthRepository`
- `features/profile/domain/repositories/profile_repository.dart` — `ProfileRepository`

## Pruebas

```bash
flutter test
flutter analyze
```

## Notas para el equipo

**El perfil ya existe cuando termina el registro.** El nombre que escribe la
usuaria viaja como metadato en el registro y el trigger `handle_new_user` lo
usa al insertar la fila de `profiles` (si falta, usa la parte local del
correo). `profiles` solo tiene políticas de RLS de `select` y `update`, así que
cualquier escritura desde el cliente debe ser un `update` sobre la fila
existente, no un `insert`. El caso de uso `CreateProfile` se conserva en el
dominio, pero el flujo actual ya no lo invoca.

**`user_preferences` se crea sola.** El mismo trigger la inserta con los valores
por defecto (`community`, notificaciones activas, `es`).

**Ruta del SDK con espacios.** `pubspec.yaml` fija
`path_provider_foundation: 2.4.1` mediante `dependency_overrides`. Las versiones
más nuevas arrastran `objective_c`, cuyo hook de *native assets* falla si la
ruta del SDK de Flutter contiene espacios (por ejemplo
`C:\Users\Nombre Apellido\flutter`). Si tu SDK está en una ruta sin espacios,
puedes quitar ese bloque.
