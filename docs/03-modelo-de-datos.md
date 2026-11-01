# 03 · Modelo de datos

Traducción completa del diagrama MER de Doulapp a una especificación ejecutable: 25 tablas en 5 módulos, con tipos, claves, relaciones y su correspondencia en Dart.

Este documento es la **fuente de verdad del modelo**. Si el código y el diagrama discrepan, manda este documento.

---

## Convenciones generales

- **Identificadores:** `UUID` en todas las tablas, salvo `roles.id` que es `SMALLINT` (catálogo corto y fijo).
- **Fechas:** `TIMESTAMPTZ` siempre, nunca `TIMESTAMP` sin zona. En Dart son `DateTime` en UTC.
- **Nomenclatura:** tablas y columnas en `snake_case` y en inglés. Las tablas de unión se nombran uniendo las dos entidades (`post_categories`, `need_session_options`).
- **Borrado:** `profiles.deleted_at` implementa borrado lógico. El resto de tablas borra en duro mediante `ON DELETE CASCADE`.
- **Notación en este documento:** `NN` = NOT NULL · `UQ` = UNIQUE · `PK` = clave primaria · `FK` = clave foránea.

---

## Decisión clave: Supabase Auth reemplaza parte del MER

El diagrama MER modela la autenticación a mano: una tabla `users` con `password_hash` y una tabla `auth_identities` para los proveedores externos. **Supabase ya hace exactamente eso**, en el esquema `auth`, que es gestionado por la plataforma y no se debe duplicar.

Por eso el modelo se reconcilia así:

| En el MER | En la implementación | Por qué |
|---|---|---|
| `users` | `auth.users` (Supabase) **+** `public.profiles` | Supabase guarda credenciales y correo; `profiles` guarda los datos públicos del perfil |
| `users.password_hash` | **No se crea** | Lo gestiona Supabase Auth |
| `users.email` | **No se duplica** | Vive en `auth.users.email` |
| `auth_identities` | **No se crea** | Equivale a `auth.identities`, que Supabase llena al usar login social |
| `users.id` | `profiles.id` → `REFERENCES auth.users(id) ON DELETE CASCADE` | El perfil comparte el `id` del usuario autenticado |

**Consecuencia práctica:** en todo el resto del esquema, donde el MER dice `FK → users.id`, el código crea `FK → profiles.id`. El valor es el mismo UUID.

Un trigger crea la fila de `profiles` automáticamente cuando Supabase inserta en `auth.users`, para que no exista un usuario autenticado sin perfil. El DDL está en `supabase/schema.sql`.

---

## Módulo IDENTIDAD

### `profiles`
Perfil del usuario. Relación 1:1 con `auth.users`.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK, FK → `auth.users.id` | Mismo UUID que el usuario autenticado |
| `display_name` | VARCHAR(100) | NN | | Nombre que se muestra |
| `avatar_url` | TEXT | NULL | | |
| `bio` | VARCHAR(280) | NULL | | |
| `account_status` | VARCHAR(20) | NN | | Ver catálogo de valores |
| `created_at` | TIMESTAMPTZ | NN | | |
| `updated_at` | TIMESTAMPTZ | NN | | |
| `deleted_at` | TIMESTAMPTZ | NULL | | Borrado lógico |

→ Entidad Dart: **`Profile`**

### `user_preferences`
Preferencias del usuario. 1:1 con `profiles`.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `profile_visibility` | VARCHAR(20) | NN | |
| `allow_notifications` | BOOLEAN | NN | |
| `wellbeing_reminders` | BOOLEAN | NN | |
| `language_code` | VARCHAR(10) | NN | |
| `updated_at` | TIMESTAMPTZ | NN | |

→ Entidad Dart: **`UserPreferences`**

### `roles`
Catálogo de roles.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | SMALLINT | NN | PK |
| `code` | VARCHAR(30) | NN | UQ |
| `name` | VARCHAR(60) | NN | |

→ Entidad Dart: **`Role`**

### `user_roles`
Asignación de roles. Tabla de unión N:M entre `profiles` y `roles`.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `role_id` | SMALLINT | NN | PK, FK → `roles.id` |
| `assigned_at` | TIMESTAMPTZ | NN | |

---

## Módulo COMUNIDAD

### `community_categories`
Catálogo de categorías de la comunidad.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `name` | VARCHAR(60) | NN | UQ |
| `slug` | VARCHAR(70) | NN | UQ |
| `is_active` | BOOLEAN | NN | |

→ Entidad Dart: **`CommunityCategory`**

### `posts`
Publicaciones de la comunidad.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `author_id` | UUID | NN | FK → `profiles.id` | |
| `post_type` | VARCHAR(20) | NN | | Ver catálogo |
| `body` | TEXT | NN | | |
| `visibility` | VARCHAR(20) | NN | | Ver catálogo |
| `status` | VARCHAR(20) | NN | | Ver catálogo. Moderación |
| `created_at` | TIMESTAMPTZ | NN | | |
| `updated_at` | TIMESTAMPTZ | NN | | |

→ Entidad Dart: **`Post`**

### `post_categories`
Unión N:M entre `posts` y `community_categories`. Una publicación puede estar en varias categorías.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `post_id` | UUID | NN | PK, FK → `posts.id` |
| `category_id` | UUID | NN | PK, FK → `community_categories.id` |

### `comments`
Comentarios. **Auto-referencia:** `parent_comment_id` permite respuestas anidadas.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `post_id` | UUID | NN | FK → `posts.id` | |
| `author_id` | UUID | NN | FK → `profiles.id` | |
| `parent_comment_id` | UUID | NULL | FK → `comments.id` | Nulo = comentario raíz |
| `body` | TEXT | NN | | |
| `status` | VARCHAR(20) | NN | | Moderación |
| `created_at` | TIMESTAMPTZ | NN | | |
| `updated_at` | TIMESTAMPTZ | NN | | |

→ Entidad Dart: **`Comment`**

### `reactions`
Reacción de un usuario a una publicación. La PK compuesta garantiza **una sola reacción por usuario y publicación**.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `post_id` | UUID | NN | PK, FK → `posts.id` |
| `reaction_type` | VARCHAR(20) | NN | |
| `created_at` | TIMESTAMPTZ | NN | |

### `saved_posts`
Publicaciones guardadas. Unión N:M.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `post_id` | UUID | NN | PK, FK → `posts.id` |
| `created_at` | TIMESTAMPTZ | NN | |

### `user_topic_follows`
Temas seguidos por el usuario. Unión N:M con categorías.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `category_id` | UUID | NN | PK, FK → `community_categories.id` |
| `created_at` | TIMESTAMPTZ | NN | |

### `post_shares`
Registro de cada vez que se comparte una publicación.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `post_id` | UUID | NN | FK → `posts.id` |
| `shared_by` | UUID | NN | FK → `profiles.id` |
| `channel` | VARCHAR(20) | NN | |
| `created_at` | TIMESTAMPTZ | NN | |

### `user_blocks`
Bloqueos entre usuarios. **Dos FK a la misma tabla**: quién bloquea y a quién.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `blocker_id` | UUID | NN | PK, FK → `profiles.id` |
| `blocked_id` | UUID | NN | PK, FK → `profiles.id` |
| `created_at` | TIMESTAMPTZ | NN | |

Restricción: `blocker_id <> blocked_id`.

### `media_assets`
Archivos subidos. Apunta a Supabase Storage mediante `storage_key`.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `owner_id` | UUID | NN | FK → `profiles.id` |
| `storage_key` | TEXT | NN | UQ |
| `media_type` | VARCHAR(10) | NN | |
| `mime_type` | VARCHAR(100) | NN | |
| `size_bytes` | BIGINT | NN | |
| `created_at` | TIMESTAMPTZ | NN | |

→ Entidad Dart: **`MediaAsset`**

### `post_media`
Multimedia de una publicación. `position` define el orden en la galería.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `post_id` | UUID | NN | PK, FK → `posts.id` |
| `media_id` | UUID | NN | PK, FK → `media_assets.id` |
| `position` | SMALLINT | NN | |
| `caption` | VARCHAR(250) | NULL | |

### `content_reports`
Reportes de contenido. Soporta reportar una publicación **o** un comentario: ambas FK son nulas y se llena solo una.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `reporter_id` | UUID | NN | FK → `profiles.id` | Quién reporta |
| `post_id` | UUID | NULL | FK → `posts.id` | |
| `comment_id` | UUID | NULL | FK → `comments.id` | |
| `reason_code` | VARCHAR(30) | NN | | |
| `details` | TEXT | NULL | | |
| `status` | VARCHAR(20) | NN | | |
| `reviewed_by` | UUID | NULL | FK → `profiles.id` | Moderador |
| `reviewed_at` | TIMESTAMPTZ | NULL | | |
| `created_at` | TIMESTAMPTZ | NN | | |

Restricción: exactamente uno de `post_id` / `comment_id` debe estar presente.

→ Entidad Dart: **`ContentReport`**

---

## Módulo MICRODESCANSOS

### `activity_categories`
Catálogo de categorías de microdescanso.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `name` | VARCHAR(60) | NN | UQ |
| `slug` | VARCHAR(70) | NN | UQ |
| `is_active` | BOOLEAN | NN | |

→ Entidad Dart: **`ActivityCategory`**

### `activities`
Las actividades de autocuidado. El contenido puede venir de tres fuentes: texto embebido, un archivo propio o un enlace externo.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `category_id` | UUID | NN | FK → `activity_categories.id` | |
| `title` | VARCHAR(120) | NN | | |
| `description` | TEXT | NN | | |
| `modality` | VARCHAR(15) | NN | | Ver catálogo |
| `duration_minutes` | SMALLINT | NN | | Permite filtrar por tiempo disponible |
| `content_text` | TEXT | NULL | | Para modalidad lectura |
| `media_id` | UUID | NULL | FK → `media_assets.id` | Para audio o video propio |
| `external_url` | TEXT | NULL | | Para recurso externo |
| `is_published` | BOOLEAN | NN | | |
| `created_at` | TIMESTAMPTZ | NN | | |
| `updated_at` | TIMESTAMPTZ | NN | | |

→ Entidad Dart: **`Activity`**

### `saved_activities`
Actividades guardadas como favoritas.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `user_id` | UUID | NN | PK, FK → `profiles.id` |
| `activity_id` | UUID | NN | PK, FK → `activities.id` |
| `created_at` | TIMESTAMPTZ | NN | |

### `activity_sessions`
Cada vez que una usuaria realiza una actividad. `completed_at` nulo = sesión abandonada o en curso.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `user_id` | UUID | NN | FK → `profiles.id` |
| `activity_id` | UUID | NN | FK → `activities.id` |
| `started_at` | TIMESTAMPTZ | NN | |
| `completed_at` | TIMESTAMPTZ | NULL | |
| `status` | VARCHAR(20) | NN | |
| `elapsed_seconds` | INTEGER | NULL | |

→ Entidad Dart: **`ActivitySession`**

---

## Módulo BIENESTAR

### `mood_checkins`
Registro del estado de ánimo.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `user_id` | UUID | NN | FK → `profiles.id` |
| `mood_score` | SMALLINT | NN | |
| `note` | VARCHAR(500) | NULL | |
| `recorded_at` | TIMESTAMPTZ | NN | |

→ Entidad Dart: **`MoodCheckin`**

### `need_options`
Catálogo de necesidades y estados para el flujo «No sé qué necesito».

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `code` | VARCHAR(40) | NN | UQ |
| `label` | VARCHAR(100) | NN | |
| `is_active` | BOOLEAN | NN | |

→ Entidad Dart: **`NeedOption`**

### `need_sessions`
Una pasada del usuario por el flujo «No sé qué necesito».

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `id` | UUID | NN | PK |
| `user_id` | UUID | NN | FK → `profiles.id` |
| `created_at` | TIMESTAMPTZ | NN | |

### `need_session_options`
Opciones elegidas en esa sesión. Unión N:M: **el flujo permite marcar varias**.

| Columna | Tipo | Nulo | Clave |
|---|---|---|---|
| `need_session_id` | UUID | NN | PK, FK → `need_sessions.id` |
| `need_option_id` | UUID | NN | PK, FK → `need_options.id` |

### `need_recommendations`
Regla que conecta una necesidad con una sugerencia. **Aquí vive la lógica de recomendación: es configuración en datos, no código.**

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `need_option_id` | UUID | NN | FK → `need_options.id` | Necesidad que dispara la sugerencia |
| `activity_id` | UUID | NULL | FK → `activities.id` | Sugerir una actividad concreta |
| `destination_code` | VARCHAR(20) | NULL | | O sugerir una sección de la app |
| `message` | VARCHAR(240) | NN | | Texto mostrado |
| `priority` | SMALLINT | NN | | Menor número = mayor prioridad |

→ Entidad Dart: **`NeedRecommendation`**

---

## Módulo NOTIFICACIONES

### `notifications`
Avisos dentro de la app. `actor_id` es quien provocó el aviso y es nulo cuando lo genera el sistema.

| Columna | Tipo | Nulo | Clave | Notas |
|---|---|---|---|---|
| `id` | UUID | NN | PK | |
| `recipient_id` | UUID | NN | FK → `profiles.id` | Destinatario |
| `actor_id` | UUID | NULL | FK → `profiles.id` | Nulo = aviso del sistema |
| `notification_type` | VARCHAR(30) | NN | | |
| `post_id` | UUID | NULL | FK → `posts.id` | Contexto opcional |
| `comment_id` | UUID | NULL | FK → `comments.id` | Contexto opcional |
| `title` | VARCHAR(120) | NN | | |
| `body` | VARCHAR(300) | NN | | |
| `is_read` | BOOLEAN | NN | | |
| `created_at` | TIMESTAMPTZ | NN | | |
| `read_at` | TIMESTAMPTZ | NULL | | |

→ Entidad Dart: **`AppNotification`** (`Notification` choca con la clase de Flutter, no lo uses)

---

## Catálogo de valores

El diagrama define estas columnas como `VARCHAR` pero no fija los valores permitidos. **Los siguientes son la propuesta de este documento**, no vienen del MER. Impleméntalos como `enum` en Dart y como `CHECK` en Postgres.

| Columna | Valores |
|---|---|
| `profiles.account_status` | `active`, `suspended`, `deactivated` |
| `user_preferences.profile_visibility` | `public`, `community`, `private` |
| `posts.post_type` | `experience`, `question`, `message` |
| `posts.visibility` | `public`, `community` |
| `posts.status` / `comments.status` | `published`, `hidden`, `removed` |
| `reactions.reaction_type` | `support`, `thanks`, `same` |
| `post_shares.channel` | `link`, `whatsapp`, `other` |
| `media_assets.media_type` | `image`, `audio`, `video` |
| `content_reports.reason_code` | `spam`, `harassment`, `misinformation`, `inappropriate`, `other` |
| `content_reports.status` | `pending`, `reviewing`, `resolved`, `dismissed` |
| `activities.modality` | `read`, `listen`, `watch`, `do` |
| `activity_sessions.status` | `in_progress`, `completed`, `abandoned` |
| `notifications.notification_type` | `comment`, `reaction`, `reply`, `system`, `reminder` |
| `need_recommendations.destination_code` | `activities`, `community`, `mood_checkin` |
| `mood_checkins.mood_score` | entero de 1 a 5 |
| `roles.code` | `user`, `moderator`, `admin` |

---

## Reglas de negocio que el esquema impone

Estas reglas ya están garantizadas por las claves y restricciones. No las reimplementes en Dart:

1. **Una reacción por usuario y publicación** — PK compuesta en `reactions`.
2. **No se puede guardar dos veces la misma publicación o actividad** — PK compuesta en `saved_posts` y `saved_activities`.
3. **Un perfil por usuario autenticado** — `profiles.id` es a la vez PK y FK a `auth.users`.
4. **Un conjunto de preferencias por usuario** — `user_preferences.user_id` es PK.
5. **Los comentarios se anidan** — `parent_comment_id` apunta a la misma tabla.
6. **Un reporte apunta a una publicación o a un comentario, nunca a ambos** — restricción `CHECK`.
7. **Nadie se bloquea a sí mismo** — restricción `CHECK`.
8. **Al borrar un usuario se borra en cascada todo lo suyo** — `ON DELETE CASCADE`.

---

## Cómo llevar esto a Flutter

Para cada tabla que entre en alcance, se crean cuatro archivos siguiendo la estructura de `docs/04-arquitectura-flutter.md`:

**1. Entidad de dominio** — clase inmutable, sin dependencias de Supabase ni de JSON. Solo los campos y `Equatable`.

```dart
class Profile extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, displayName, avatarUrl, bio, accountStatus, createdAt, updatedAt];
}
```

**2. Modelo de datos** — extiende la entidad y añade `fromJson` / `toJson`. Las claves del JSON son **exactamente** los nombres de columna en `snake_case`.

```dart
class ProfileModel extends Profile {
  const ProfileModel({ ... });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    bio: json['bio'] as String?,
    accountStatus: AccountStatus.fromCode(json['account_status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'account_status': accountStatus.code,
  };
}
```

En `toJson` **no incluyas** `created_at`, `updated_at` ni `id` generados por la base de datos cuando estés insertando; deja que Postgres ponga los valores por defecto.

**3. DataSource** — habla con Supabase y nada más. Devuelve modelos o lanza excepciones.

```dart
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<ProfileModel> updateProfile(ProfileModel profile);
}
```

**4. Repositorio** — interfaz en `domain`, implementación en `data`. Convierte excepciones en `Failure` y devuelve `Either<Failure, T>`.

### Reglas de mapeo

- Columna `NULL` → campo Dart anulable (`String?`).
- Columna `NN` → campo `required` y no anulable.
- `TIMESTAMPTZ` → `DateTime`, siempre parseado con `DateTime.parse` y tratado en UTC.
- `BOOLEAN` → `bool`.
- `SMALLINT` / `INTEGER` / `BIGINT` → `int`.
- `UUID` → `String`.
- Columnas del catálogo de valores → `enum` Dart con un `code` de respaldo, nunca `String` suelto.
- Tablas de unión con PK compuesta → normalmente **no** necesitan entidad propia. Se modelan como lista dentro de la entidad padre o como método del repositorio (`saveActivity`, `unsaveActivity`).
