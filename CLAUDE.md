# Doulapp

App móvil Flutter de acompañamiento posparto. Proyecto académico, Universidad Icesi.

> **Tagline:** «Tu bienestar también importa.»
> La app acompaña a la **persona que cuida**, no al bebé.

## Stack

| Capa | Tecnología |
|---|---|
| App | Flutter (Dart 3) |
| Estado | BLoC (`flutter_bloc`) |
| Arquitectura | Clean Architecture por feature |
| Backend | Supabase (Auth + Postgres + Storage) |
| Inyección | `get_it` |

## Documentación

Lee el documento que corresponda antes de escribir código:

| Archivo | Cuándo leerlo |
|---|---|
| `docs/01-producto.md` | Para entender el tono, a quién va dirigida y qué NO debe parecer |
| `docs/02-funcionalidades.md` | Listado funcional completo por módulo |
| `docs/03-modelo-de-datos.md` | **Esquema de base de datos completo + mapeo a Dart.** Es la fuente de verdad del modelo |
| `docs/04-arquitectura-flutter.md` | Estructura de carpetas, capas, convenciones de nombres, tema visual |
| `docs/05-entrega-actual.md` | Qué está en alcance ahora mismo y quién hace qué |
| `supabase/schema.sql` | DDL listo para ejecutar en Supabase |

## Reglas del proyecto

**Alcance.** Solo se implementa lo que está en `docs/05-entrega-actual.md`. El modelo de datos cubre la app completa, pero la entrega actual es mucho más pequeña. No construyas módulos que no estén en alcance.

**Autenticación.** La identidad la maneja **Supabase Auth**. No crees tablas de usuarios con contraseñas ni tablas de identidades de proveedor: ya existen en el esquema `auth`. Ver la sección «Identidad» de `docs/03-modelo-de-datos.md`, que explica cómo se reconcilia esto con el diagrama MER.

**Nombres.** Código, identificadores y nombres de archivo en inglés. Textos de interfaz, en español. Tablas y columnas en `snake_case`; clases Dart en `PascalCase`.

**Comentarios.** Escribe comentarios solo donde una decisión no sea evidente leyendo el código. Nada de encabezados con el nombre del archivo, referencias al enunciado, al diagrama o a la tarea. El código debe leerse como escrito por una persona.

**Secretos.** La URL y la anon key de Supabase van en `.env` (con `flutter_dotenv`), nunca en el código fuente. `.env` va en `.gitignore`; deja un `.env.example` con las claves vacías.

**Errores.** Las capas de datos lanzan `Exception`; los repositorios las convierten en `Failure` y devuelven `Either<Failure, T>` (`dartz`). La UI nunca ve una excepción cruda.

## Lenguaje de la interfaz

El tono del producto es parte del requisito, no decoración:

- Nunca uses lenguaje que genere culpa. No hay metas, rachas, porcentajes ni «cumpliste tu objetivo».
- Los mensajes de error explican qué pasó y qué hacer, sin disculparse.
- Botones en infinitivo o imperativo corto: «Crear mi cuenta», «Continuar», «Comenzar».
- Si una sección no está disponible, se muestra marcada como «Próximamente» y **no navega a ninguna parte**.
