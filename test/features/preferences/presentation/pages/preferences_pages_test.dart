import 'package:bloc_test/bloc_test.dart';
import 'package:doulapp/features/preferences/domain/entities/profile_visibility.dart';
import 'package:doulapp/features/preferences/domain/entities/user_preferences.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_event.dart';
import 'package:doulapp/features/preferences/presentation/bloc/preferences_state.dart';
import 'package:doulapp/features/preferences/presentation/pages/notifications_page.dart';
import 'package:doulapp/features/preferences/presentation/pages/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesBloc extends MockBloc<PreferencesEvent, PreferencesState>
    implements PreferencesBloc {}

void main() {
  late MockPreferencesBloc bloc;

  const prefs = UserPreferences(
    profileVisibility: ProfileVisibility.community,
    allowNotifications: true,
    wellbeingReminders: false,
    languageCode: 'es',
  );

  setUpAll(() => registerFallbackValue(const PreferencesLoadRequested()));
  setUp(() => bloc = MockPreferencesBloc());

  Widget wrap(Widget page) => MaterialApp(
    home: BlocProvider<PreferencesBloc>.value(value: bloc, child: page),
  );

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('NotificationsPage', () {
    testWidgets('muestra el estado actual de los interruptores', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesLoaded(preferences: prefs));

      await t.pumpWidget(wrap(const NotificationsPage()));

      expect(
        t
            .widget<SwitchListTile>(
              find.byKey(const Key('preferences_notifications_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        t
            .widget<SwitchListTile>(
              find.byKey(const Key('preferences_reminders_switch')),
            )
            .value,
        isFalse,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('cada interruptor envía su evento', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesLoaded(preferences: prefs));

      await t.pumpWidget(wrap(const NotificationsPage()));
      await t.tap(find.byKey(const Key('preferences_notifications_switch')));
      await t.tap(find.byKey(const Key('preferences_reminders_switch')));

      verify(
        () => bloc.add(const PreferencesNotificationsChanged(false)),
      ).called(1);
      verify(() => bloc.add(const PreferencesRemindersChanged(true))).called(1);
    });

    testWidgets('bloquea los interruptores mientras guarda', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesLoaded(preferences: prefs, isSaving: true));

      await t.pumpWidget(wrap(const NotificationsPage()));
      await t.tap(find.byKey(const Key('preferences_notifications_switch')));

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('muestra el error y permite reintentar', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesFailure('Sin conexión'));

      await t.pumpWidget(wrap(const NotificationsPage()));
      expect(find.text('Sin conexión'), findsOneWidget);

      await t.tap(find.byKey(const Key('preferences_retry_button')));
      verify(() => bloc.add(const PreferencesLoadRequested())).called(1);
    });

    testWidgets('avisa con un mensaje cuando un cambio no se guardó', (
      t,
    ) async {
      useSmallPhone(t);
      whenListen(
        bloc,
        Stream.value(
          const PreferencesLoaded(
            preferences: prefs,
            errorMessage: 'No se pudo guardar',
          ),
        ),
        initialState: const PreferencesLoaded(preferences: prefs),
      );

      await t.pumpWidget(wrap(const NotificationsPage()));
      await t.pump();

      expect(find.text('No se pudo guardar'), findsOneWidget);
    });
  });

  group('PrivacyPage', () {
    testWidgets('marca la visibilidad actual y muestra el uso de datos', (
      t,
    ) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesLoaded(preferences: prefs));

      await t.pumpWidget(wrap(const PrivacyPage()));

      expect(find.byKey(const Key('privacy_option_public')), findsOneWidget);
      expect(find.byKey(const Key('privacy_option_community')), findsOneWidget);
      expect(find.byKey(const Key('privacy_option_private')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('privacy_option_community')),
          matching: find.byIcon(Icons.radio_button_checked_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Cómo usamos tus datos'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('elegir otra opción envía el cambio de visibilidad', (t) async {
      useSmallPhone(t);
      when(
        () => bloc.state,
      ).thenReturn(const PreferencesLoaded(preferences: prefs));

      await t.pumpWidget(wrap(const PrivacyPage()));
      await t.tap(find.byKey(const Key('privacy_option_private')));

      verify(
        () => bloc.add(
          const PreferencesVisibilityChanged(ProfileVisibility.private),
        ),
      ).called(1);
    });

    testWidgets('muestra la carga mientras llegan las preferencias', (t) async {
      useSmallPhone(t);
      when(() => bloc.state).thenReturn(const PreferencesLoading());

      await t.pumpWidget(wrap(const PrivacyPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
