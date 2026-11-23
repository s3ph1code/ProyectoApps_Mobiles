import 'package:doulapp/core/theme/app_theme.dart';
import 'package:doulapp/core/widgets/app_card.dart';
import 'package:doulapp/core/widgets/screen_header.dart';
import 'package:doulapp/core/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinta cada componente compartido en un teléfono de 390 × 844 con el tema
/// real y verifica que se muestra sin desbordes.
void main() {
  Future<void> pumpOnPhone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('AppCard muestra su contenido y responde al toque', (
    tester,
  ) async {
    var tapped = false;
    await pumpOnPhone(
      tester,
      Center(
        child: AppCard(
          onTap: () => tapped = true,
          child: const Text('Contenido de la tarjeta'),
        ),
      ),
    );

    expect(find.text('Contenido de la tarjeta'), findsOneWidget);
    await tester.tap(find.byType(AppCard));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoadingView muestra el indicador y su etiqueta', (tester) async {
    await pumpOnPhone(tester, const LoadingView(label: 'Cargando…'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EmptyStateView muestra icono, título y mensaje', (tester) async {
    await pumpOnPhone(
      tester,
      const EmptyStateView(
        icon: Icons.inbox_outlined,
        title: 'Aún no hay nada',
        message: 'Cuando haya contenido, aparecerá aquí.',
      ),
    );

    expect(find.text('Aún no hay nada'), findsOneWidget);
    expect(find.text('Cuando haya contenido, aparecerá aquí.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ErrorStateView reintenta al pulsar la acción', (tester) async {
    var retried = false;
    await pumpOnPhone(
      tester,
      ErrorStateView(
        message: 'No pudimos cargar la información.',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Algo salió mal'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScreenHeader muestra título, subtítulo y acción', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      ScreenHeader(
        title: 'Mi bienestar',
        subtitle: 'Un espacio para ti',
        trailing: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Mi bienestar'), findsOneWidget);
    expect(find.text('Un espacio para ti'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
