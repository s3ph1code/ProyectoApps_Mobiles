# 04 · Arquitectura Flutter

Clean Architecture por feature, con BLoC en la capa de presentación y Supabase como backend.

## Regla de dependencias

```
presentation  →  domain  ←  data
```

`domain` no depende de nadie. No importa `supabase_flutter`, ni `flutter`, ni nada externo: solo entidades, interfaces de repositorio y casos de uso.

`data` implementa las interfaces de `domain`. Es el único lugar donde aparece Supabase.

`presentation` depende de `domain` a través de los casos de uso. **Nunca** llama a un DataSource ni a Supabase directamente.

## Estructura de carpetas

```
lib/
├── main.dart
├── injection_container.dart          # registro de get_it
│
├── core/
│   ├── config/
│   │   └── supabase_config.dart      # init del cliente, lee .env
│   ├── error/
│   │   ├── exceptions.dart           # ServerException, AuthException, CacheException
│   │   └── failures.dart             # Failure y sus subtipos
│   ├── usecase/
│   │   └── usecase.dart              # abstract class UseCase<Type, Params>
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_typography.dart
│       └── app_theme.dart
│
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/         # implementaciones
        ├── domain/
        │   ├── entities/
        │   ├── repositories/         # interfaces abstractas
        │   └── usecases/
        └── presentation/
            ├── bloc/
            ├── pages/
            └── widgets/
```

### Features previstas

`auth` · `profile` · `onboarding` · `home` · `activities` · `community` · `wellbeing` · `needs` · `notifications`

Crea solo las que estén en alcance. Ver `docs/05-entrega-actual.md`.

## Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivo | `snake_case.dart` | `auth_remote_datasource.dart` |
| Entidad | `PascalCase`, singular | `Profile` |
| Modelo | entidad + `Model` | `ProfileModel` |
| Interfaz de repositorio | entidad + `Repository` | `ProfileRepository` |
| Implementación | interfaz + `Impl` | `ProfileRepositoryImpl` |
| DataSource | entidad + `RemoteDataSource` | `ProfileRemoteDataSource` |
| Caso de uso | verbo en infinitivo | `SignInWithEmail`, `GetProfile` |
| BLoC | contexto + `Bloc` | `LoginBloc`, `RegisterBloc` |
| Evento | pasado o imperativo | `LoginSubmitted` |
| Estado | adjetivo o sustantivo | `LoginLoading`, `LoginSuccess`, `LoginFailure` |

## Patrón de caso de uso

```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
```

Cada caso de uso hace **una** cosa y se invoca con `call`, así que se usa como función: `await signIn(params)`.

## Patrón de BLoC

Tres estados mínimos por flujo: inicial, cargando, resultado. El resultado se parte en éxito y error.

```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInWithEmail signIn;

  LoginBloc({required this.signIn}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    final result = await signIn(SignInParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }
}
```

La UI reacciona con `BlocConsumer`: `listener` para navegar o mostrar mensajes, `builder` para pintar.

## Manejo de errores

```
DataSource lanza Exception  →  Repository la captura  →  devuelve Left(Failure)  →  BLoC emite estado de error  →  UI muestra mensaje en español
```

Los mensajes que ve la usuaria se escriben en el BLoC o en la UI, nunca en el DataSource. Deben explicar qué pasó y qué hacer, sin tecnicismos y sin disculpas.

## Inyección de dependencias

`get_it` registrado en `injection_container.dart`:

- BLoC → `registerFactory` (instancia nueva por pantalla)
- Casos de uso, repositorios y datasources → `registerLazySingleton`
- Cliente de Supabase → `registerLazySingleton`

En la UI se proveen con `BlocProvider(create: (_) => sl<LoginBloc>())`.

## Tema visual

Los colores salen de `docs/01-producto.md` y deben vivir en `core/theme/app_colors.dart` como constantes, nunca escritos a mano en los widgets.

```dart
class AppColors {
  static const sage       = Color(0xFF588157);
  static const sageLight  = Color(0xFFA3B18A);
  static const sageDark   = Color(0xFF395A3F);
  static const cream      = Color(0xFFF7F5EF);
  static const beige      = Color(0xFFEDE8DE);
  static const surface    = Color(0xFFFFFFFF);
  static const ink        = Color(0xFF26382D);
  static const inkSoft    = Color(0xFF68736C);
  static const success    = Color(0xFF6F9B72);
  static const warning    = Color(0xFFD8B36A);
  static const error      = Color(0xFFB85C5C);
}
```

**Tipografía:** Fraunces para titulares, Inter para interfaz y cuerpo. Se cargan con `google_fonts`.

**Radios:** 10 / 14 / 18 / 24 / 30 px, y `StadiumBorder` para los botones.

**Botón primario:** 56 px de alto, ancho completo, esquinas redondeadas al máximo, fondo `sage`, texto blanco.

**Fondo de pantalla:** `cream`. Superficies de tarjeta: `surface`.

## Paquetes

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  dartz: ^0.10.1
  get_it: ^7.7.0
  supabase_flutter: ^2.5.6
  flutter_dotenv: ^5.1.0
  google_fonts: ^6.2.1
  go_router: ^14.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  flutter_lints: ^4.0.0
```

Fija las versiones al crear el proyecto y no las muevas durante la entrega.
