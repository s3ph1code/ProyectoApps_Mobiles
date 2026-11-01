# 02 · Funcionalidades

Listado funcional completo de Doulapp, por módulo. Cada elemento es el nombre de la funcionalidad y una descripción breve de su propósito.

> Este documento describe **la app completa**. Lo que se implementa en la entrega en curso está en `docs/05-entrega-actual.md`.

---

## 1. Cuenta y configuración inicial

| Funcionalidad | Descripción |
|---|---|
| Crear cuenta | Permite registrarse para acceder a las funciones personalizadas de Doulapp. |
| Iniciar sesión | Permite acceder de forma segura a una cuenta existente. |
| Cerrar sesión | Finaliza la sesión activa en el dispositivo. |
| Recuperar acceso | Guía al usuario en el proceso de recuperación de su cuenta. |
| Onboarding | Presenta el propósito de Doulapp y recoge la información inicial necesaria para adaptar la experiencia. |

## 2. Inicio y navegación

| Funcionalidad | Descripción |
|---|---|
| Pantalla de inicio | Reúne accesos a las funciones principales y presenta sugerencias o contenido de acompañamiento disponible. |
| Navegación entre módulos | Permite desplazarse entre las secciones de la aplicación de forma clara y consistente. |

## 3. Microdescansos

| Funcionalidad | Descripción |
|---|---|
| Explorar actividades | Permite descubrir pausas breves de autocuidado organizadas por categorías. |
| Consultar detalle de actividad | Muestra la descripción, duración aproximada e instrucciones de una actividad. |
| Realizar actividad | Acompaña al usuario mientras sigue los pasos de un microdescanso. |
| Finalizar sesión | Permite marcar una actividad como completada y registrar la sesión cuando la función está habilitada. |
| Guardar actividad | Permite conservar actividades favoritas para encontrarlas más fácilmente. |
| Consultar actividades guardadas | Muestra la lista personal de actividades guardadas. |

## 4. Comunidad de madres

| Funcionalidad | Descripción |
|---|---|
| Consultar publicaciones | Permite leer experiencias, preguntas y mensajes compartidos por otras madres. |
| Explorar categorías y temas | Organiza las publicaciones por categorías para facilitar la búsqueda de contenido relevante. |
| Crear publicación | Permite compartir una experiencia, pregunta o mensaje con la comunidad. |
| Adjuntar contenido multimedia | Permite añadir imágenes u otros archivos a una publicación si la carga multimedia está habilitada. |
| Comentar publicaciones | Permite responder a una publicación y participar en la conversación. |
| Responder comentarios | Permite continuar una conversación respondiendo a un comentario cuando esa opción está habilitada. |
| Reaccionar a publicaciones | Permite expresar una reacción mediante las opciones disponibles. |
| Guardar publicaciones | Permite conservar publicaciones para consultarlas posteriormente. |
| Seguir temas | Permite indicar interés en temas y facilitar el acceso a contenido relacionado. |
| Compartir publicación | Permite compartir una referencia o enlace a una publicación cuando la plataforma lo permite. |
| Reportar contenido | Permite informar sobre publicaciones o interacciones que podrían incumplir las normas de la aplicación. |
| Bloquear usuario | Permite limitar la interacción con una persona según las reglas de la aplicación. |

## 5. «No sé qué necesito»

| Funcionalidad | Descripción |
|---|---|
| Identificar una necesidad | Ofrece opciones guiadas para que la persona pueda expresar qué necesita cuando no sabe cómo describirlo. |
| Seleccionar opciones | Permite elegir una o varias necesidades o estados, de acuerdo con el flujo disponible. |
| Recibir recomendaciones | Presenta sugerencias relacionadas con las opciones seleccionadas. |
| Acceder a una función recomendada | Facilita pasar desde una recomendación a una actividad o recurso disponible en Doulapp. |

## 6. Bienestar emocional

| Funcionalidad | Descripción |
|---|---|
| Check-in de estado de ánimo | Permite registrar cómo se siente la persona en un momento determinado. |
| Consultar registros anteriores | Permite revisar registros de bienestar guardados, si existe una vista de historial. |
| Omitir el check-in | Permite continuar utilizando la aplicación sin registrar el estado de ánimo. |

## 7. Perfil y preferencias

| Funcionalidad | Descripción |
|---|---|
| Consultar perfil | Muestra la información básica asociada a la cuenta. |
| Editar perfil | Permite actualizar los datos personales que la aplicación tenga habilitados para edición. |
| Configurar preferencias | Permite ajustar preferencias personales o de contenido disponibles. |
| Gestionar privacidad y cuenta | Da acceso a las opciones disponibles para controlar la cuenta y consultar información sobre el uso de datos. |

## 8. Notificaciones

| Funcionalidad | Descripción |
|---|---|
| Avisos dentro de la aplicación | Muestra notificaciones relacionadas con eventos o actividad relevante de Doulapp cuando están habilitadas. |
| Gestionar preferencias de notificación | Permite ajustar las categorías de avisos que el usuario desea recibir, según las opciones disponibles. |

## 9. Seguridad y moderación

| Funcionalidad | Descripción |
|---|---|
| Control de acceso | Restringe las funciones privadas a usuarios autenticados. |
| Permisos por rol | Limita las acciones disponibles según el rol asignado a cada cuenta. |
| Revisión de reportes | Permite que un rol autorizado revise reportes de la comunidad si se implementa el flujo de moderación. |
| Gestión de contenido | Aplica las reglas definidas para proteger la comunidad y administrar contenido reportado. |

---

## Trazabilidad funcionalidad → tablas

| Módulo funcional | Tablas principales |
|---|---|
| 1. Cuenta y configuración | `profiles`, `user_preferences`, `roles`, `user_roles` (+ `auth.users` de Supabase) |
| 3. Microdescansos | `activity_categories`, `activities`, `saved_activities`, `activity_sessions` |
| 4. Comunidad | `posts`, `comments`, `reactions`, `community_categories`, `post_categories`, `post_media`, `saved_posts`, `post_shares`, `user_topic_follows`, `user_blocks`, `media_assets` |
| 5. «No sé qué necesito» | `need_options`, `need_sessions`, `need_session_options`, `need_recommendations` |
| 6. Bienestar emocional | `mood_checkins` |
| 7. Perfil y preferencias | `profiles`, `user_preferences` |
| 8. Notificaciones | `notifications`, `user_preferences.allow_notifications` |
| 9. Seguridad y moderación | `roles`, `user_roles`, `content_reports`, `posts.status`, `comments.status` |
