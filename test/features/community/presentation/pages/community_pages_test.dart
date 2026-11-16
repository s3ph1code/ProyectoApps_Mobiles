import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/core/router/app_router.dart';
import 'package:doulapp/features/community/domain/entities/post_type.dart';
import 'package:doulapp/features/community/domain/entities/post_visibility.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_event.dart';
import 'package:doulapp/features/community/presentation/bloc/create_post_state.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_event.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_state.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_event.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_state.dart';
import 'package:doulapp/features/community/presentation/pages/create_post_page.dart';
import 'package:doulapp/features/community/presentation/pages/feed_page.dart';
import 'package:doulapp/features/community/presentation/pages/post_detail_page.dart';
import 'package:doulapp/features/community/presentation/utils/community_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures.dart';

class MockFeedBloc extends MockBloc<FeedEvent, FeedState> implements FeedBloc {}

class MockPostDetailBloc extends MockBloc<PostDetailEvent, PostDetailState>
    implements PostDetailBloc {}

class MockCreatePostBloc extends MockBloc<CreatePostEvent, CreatePostState>
    implements CreatePostBloc {}

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const FeedRequested());
    registerFallbackValue(const PostDetailRequested(''));
    registerFallbackValue(const CreatePostStarted());
  });

  group('FeedPage', () {
    late MockFeedBloc bloc;

    setUp(() => bloc = MockFeedBloc());

    /// [composerResult] es lo que devuelve la pantalla «Escribir» al cerrarse.
    Widget build({bool? composerResult}) {
      final router = GoRouter(
        initialLocation: AppRoutes.community,
        routes: [
          GoRoute(
            path: AppRoutes.community,
            builder: (_, _) => BlocProvider<FeedBloc>.value(
              value: bloc,
              child: const FeedPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.createPost,
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(composerResult),
                child: const Text('Cerrar escribir'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.postDetail,
            builder: (_, state) =>
                Scaffold(body: Text('Detalle ${state.pathParameters['id']}')),
          ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    FeedLoaded loaded({String? category, bool hasMore = false}) => FeedLoaded(
      categories: testCategories,
      posts: [
        makePost('p1', authorName: 'Ana', categories: const [emotions]),
        makePost('p2', authorName: null, type: PostType.experience),
      ],
      selectedCategoryId: category,
      hasMore: hasMore,
    );

    testWidgets('muestra autora, tipo, extracto, categorías y contadores', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(loaded());

      await tester.pumpWidget(build());

      expect(find.text('Comunidad'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text(anonymousAuthorName), findsOneWidget);
      expect(find.text('Pregunta'), findsOneWidget);
      expect(find.text('Experiencia'), findsOneWidget);
      expect(
        find.text('De noche todo se siente más pesado.'),
        findsNWidgets(2),
      );
      expect(find.byKey(const Key('post_reactions_p1')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('post_comments_p1')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('los chips filtran por categoría y «Todas» quita el filtro', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(loaded(category: 'cat-1'));

      await tester.pumpWidget(build());
      await tester.ensureVisible(find.byKey(const Key('feed_filter_cat-2')));
      await tester.tap(find.byKey(const Key('feed_filter_cat-2')));
      await tester.ensureVisible(find.byKey(const Key('feed_filter_all')));
      await tester.tap(find.byKey(const Key('feed_filter_all')));

      verify(() => bloc.add(const FeedCategorySelected('cat-2'))).called(1);
      verify(() => bloc.add(const FeedCategorySelected(null))).called(1);
    });

    testWidgets('tocar una publicación abre su detalle', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(loaded());

      await tester.pumpWidget(build());
      await tester.tap(find.byKey(const Key('feed_post_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Detalle p1'), findsOneWidget);
    });

    testWidgets('al bajar hasta el final pide la página siguiente', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        FeedLoaded(
          categories: testCategories,
          posts: makePosts(20),
          hasMore: true,
        ),
      );

      await tester.pumpWidget(build());
      await tester.drag(
        find.byKey(const Key('feed_list')),
        const Offset(0, -6000),
      );
      await tester.pump();

      verify(
        () => bloc.add(const FeedNextPageRequested()),
      ).called(greaterThan(0));
    });

    testWidgets(
      'si falla la página siguiente deja reintentar sin perder la lista',
      (tester) async {
        usePhone(tester);
        when(() => bloc.state).thenReturn(
          loaded(hasMore: true).copyWith(loadMoreError: 'No hay conexión.'),
        );

        await tester.pumpWidget(build());

        expect(find.byKey(const Key('feed_post_p1')), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('feed_load_more_retry')),
          200,
          scrollable: find.descendant(
            of: find.byKey(const Key('feed_list')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.byKey(const Key('feed_load_more_retry')));

        verify(
          () => bloc.add(const FeedNextPageRequested()),
        ).called(greaterThan(0));
      },
    );

    testWidgets('con la lista vacía de una categoría ofrece ver todas', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        const FeedLoaded(
          categories: testCategories,
          posts: [],
          selectedCategoryId: 'cat-1',
        ),
      );

      await tester.pumpWidget(build());

      expect(
        find.text('Aún no hay publicaciones en esta categoría'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('feed_empty_show_all')));
      verify(() => bloc.add(const FeedCategorySelected(null))).called(1);
    });

    testWidgets('ante un error muestra el mensaje y permite reintentar', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(const FeedFailure('No hay conexión.'));

      await tester.pumpWidget(build());

      expect(find.text('No hay conexión.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('feed_retry_button')));
      verify(() => bloc.add(const FeedRequested())).called(1);
    });

    testWidgets('al publicar desde «Escribir» vuelve a «Todas»', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(loaded(category: 'cat-2'));

      await tester.pumpWidget(build(composerResult: true));
      await tester.tap(find.byKey(const Key('feed_write_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar escribir'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const FeedCategorySelected(null))).called(1);
    });

    testWidgets('salir de «Escribir» sin publicar no recarga', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(loaded());

      await tester.pumpWidget(build(composerResult: false));
      await tester.tap(find.byKey(const Key('feed_write_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar escribir'));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(any()));
    });
  });

  group('PostDetailPage', () {
    late MockPostDetailBloc bloc;

    setUp(() => bloc = MockPostDetailBloc());

    Widget build() => MaterialApp(
      home: BlocProvider<PostDetailBloc>.value(
        value: bloc,
        child: const PostDetailPage(postId: 'p0'),
      ),
    );

    testWidgets(
      'muestra el texto completo y los comentarios con sus respuestas',
      (tester) async {
        usePhone(tester);
        final longBody = 'Una línea larga. ' * 10;
        when(() => bloc.state).thenReturn(
          PostDetailLoaded(
            post: makePost('p0', body: longBody),
            comments: [
              makeComment('c1'),
              makeComment('r1', parent: 'c1'),
            ],
          ),
        );

        await tester.pumpWidget(build());

        final body = tester.widget<Text>(find.text(longBody));
        expect(body.maxLines, isNull);
        expect(find.text('Comentarios (2)'), findsOneWidget);
        expect(find.text('Comentario c1'), findsOneWidget);
        expect(find.text('Comentario r1'), findsOneWidget);
        final reply = tester.widget<Padding>(
          find.byKey(const Key('comment_r1')),
        );
        expect(reply.padding, const EdgeInsets.only(left: 28));
      },
    );

    testWidgets('sin comentarios lo dice', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        PostDetailLoaded(post: makePost('p0', comments: 0), comments: const []),
      );

      await tester.pumpWidget(build());

      expect(find.byKey(const Key('post_detail_no_comments')), findsOneWidget);
    });

    testWidgets('ante un error permite reintentar', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        const PostDetailFailure('Esa publicación ya no está disponible.'),
      );

      await tester.pumpWidget(build());
      await tester.tap(find.byKey(const Key('post_detail_retry')));

      verify(() => bloc.add(const PostDetailRequested('p0'))).called(1);
    });
  });

  group('CreatePostPage', () {
    late MockCreatePostBloc bloc;

    setUp(() => bloc = MockCreatePostBloc());

    const editing = CreatePostState(
      status: CreatePostStatus.editing,
      categories: testCategories,
    );

    Widget build() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await context.push<bool>(AppRoutes.createPost);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('resultado $result')),
                    );
                  }
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.createPost,
            builder: (_, _) => BlocProvider<CreatePostBloc>.value(
              value: bloc,
              child: const CreatePostPage(),
            ),
          ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    /// [settle] en falso para estados con animaciones infinitas (el
    /// indicador de envío), donde pumpAndSettle nunca termina.
    Future<void> open(WidgetTester tester, {bool settle = true}) async {
      await tester.pumpWidget(build());
      await tester.tap(find.text('Abrir'));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('muestra tipo, categorías, texto y visibilidad', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(editing);

      await open(tester);

      expect(find.text('Experiencia'), findsOneWidget);
      expect(find.text('Pregunta'), findsOneWidget);
      expect(find.text('Mensaje'), findsOneWidget);
      expect(find.text('Emociones'), findsOneWidget);
      expect(find.byKey(const Key('create_post_body')), findsOneWidget);
      expect(find.text(PostVisibility.community.label), findsOneWidget);
      expect(find.text(PostVisibility.public.label), findsOneWidget);
      expect(find.text('Publicar'), findsOneWidget);
    });

    testWidgets('cada elección llega al BLoC', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(editing);

      await open(tester);
      await tester.tap(find.byKey(const Key('create_post_type_question')));
      await tester.tap(find.byKey(const Key('create_post_category_cat-2')));
      await tester.enterText(find.byKey(const Key('create_post_body')), 'Hola');
      await tester.ensureVisible(
        find.byKey(const Key('create_post_visibility_public')),
      );
      await tester.tap(find.byKey(const Key('create_post_visibility_public')));
      await tester.tap(find.byKey(const Key('create_post_submit')));

      verify(
        () => bloc.add(const CreatePostTypeChanged(PostType.question)),
      ).called(1);
      verify(
        () => bloc.add(const CreatePostCategoryToggled('cat-2')),
      ).called(1);
      verify(() => bloc.add(const CreatePostBodyChanged('Hola'))).called(1);
      verify(
        () =>
            bloc.add(const CreatePostVisibilityChanged(PostVisibility.public)),
      ).called(1);
      verify(() => bloc.add(const CreatePostSubmitted())).called(1);
    });

    testWidgets('muestra el error y conserva lo escrito', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        editing.copyWith(
          body: 'Lo que escribí',
          errorMessage: 'No hay conexión.',
        ),
      );

      await open(tester);

      expect(find.byKey(const Key('create_post_error')), findsOneWidget);
      expect(find.text('Lo que escribí'), findsOneWidget);
    });

    testWidgets('mientras publica no deja volver a enviar', (tester) async {
      usePhone(tester);
      when(
        () => bloc.state,
      ).thenReturn(editing.copyWith(status: CreatePostStatus.submitting));

      await open(tester, settle: false);

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('create_post_submit')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('al publicar se cierra devolviendo true', (tester) async {
      usePhone(tester);
      whenListen(
        bloc,
        Stream.fromIterable([
          editing.copyWith(status: CreatePostStatus.submitting),
          editing.copyWith(status: CreatePostStatus.success),
        ]),
        initialState: editing,
      );

      await open(tester);
      await tester.pumpAndSettle();

      expect(find.byType(CreatePostPage), findsNothing);
      expect(find.text('resultado true'), findsOneWidget);
    });

    testWidgets('cerrar sin publicar devuelve false', (tester) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(editing);

      await open(tester);
      await tester.tap(find.byKey(const Key('create_post_close')));
      await tester.pumpAndSettle();

      expect(find.text('resultado false'), findsOneWidget);
    });

    testWidgets('si no cargan las categorías permite reintentar', (
      tester,
    ) async {
      usePhone(tester);
      when(() => bloc.state).thenReturn(
        const CreatePostState(
          status: CreatePostStatus.categoriesFailure,
          errorMessage: 'No hay conexión.',
        ),
      );

      await open(tester);
      await tester.tap(find.byKey(const Key('create_post_retry')));

      verify(() => bloc.add(const CreatePostStarted())).called(1);
    });
  });
}
