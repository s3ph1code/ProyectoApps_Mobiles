import 'package:doulapp/core/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/features/community/domain/entities/post.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_event.dart';
import 'package:doulapp/features/community/presentation/bloc/feed_state.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_bloc.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_event.dart';
import 'package:doulapp/features/community/presentation/bloc/post_detail_state.dart';
import 'package:doulapp/features/community/presentation/pages/feed_page.dart';
import 'package:doulapp/features/community/presentation/pages/post_detail_page.dart';
import 'package:doulapp/features/community/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../community/fixtures.dart';

class MockFeedBloc extends MockBloc<FeedEvent, FeedState> implements FeedBloc {}

class MockPostDetailBloc extends MockBloc<PostDetailEvent, PostDetailState>
    implements PostDetailBloc {}

void main() {
  void usePhone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  // Solo las publicaciones ajenas llevan menú; la de `author-p1` es «mía».
  Widget? menuFor(BuildContext context, Post post) {
    if (post.authorId == 'author-p1') return null;
    return Icon(Icons.more_horiz_rounded, key: Key('menu_${post.id}'));
  }

  testWidgets('PostCard sin menú no muestra nada extra', (t) async {
    usePhone(t);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: PostCard(post: makePost('p1'))),
      ),
    );

    expect(find.byKey(const Key('menu_p1')), findsNothing);
  });

  testWidgets('PostCard muestra el menú en la esquina', (t) async {
    usePhone(t);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: makePost('p1'),
            menu: const Icon(Icons.more_horiz_rounded, key: Key('menu_p1')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('menu_p1')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('con nombre muy largo y el «⋯» real no hay desbordes', (t) async {
    usePhone(t);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: makePost(
              'p1',
              authorName: 'María de los Ángeles Fernández de la Vega Ortiz',
            ),
            menu: IconButton(
              icon: const Icon(Icons.more_horiz_rounded),
              visualDensity: VisualDensity.compact,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(t.takeException(), isNull);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  testWidgets('el feed pone el menú solo en publicaciones ajenas', (t) async {
    usePhone(t);
    final bloc = MockFeedBloc();
    registerFallbackValue(const FeedRequested());
    when(() => bloc.state).thenReturn(
      FeedLoaded(
        categories: testCategories,
        posts: [makePost('p1'), makePost('p2')],
      ),
    );

    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<FeedBloc>.value(
          value: bloc,
          child: FeedPage(postMenuBuilder: menuFor),
        ),
      ),
    );

    expect(find.byKey(const Key('menu_p1')), findsNothing);
    expect(find.byKey(const Key('menu_p2')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('el detalle muestra el menú de la publicación', (t) async {
    usePhone(t);
    final bloc = MockPostDetailBloc();
    when(
      () => bloc.state,
    ).thenReturn(PostDetailLoaded(post: makePost('p2'), comments: const []));

    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<PostDetailBloc>.value(
          value: bloc,
          child: PostDetailPage(postId: 'p2', postMenuBuilder: menuFor),
        ),
      ),
    );

    expect(find.byKey(const Key('menu_p2')), findsOneWidget);
  });
}
