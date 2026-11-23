import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/ui/theme/rango_theme.dart';
import 'package:rango/ui/welcome/welcome_screen.dart';

void main() {
  Future<void> pumpWelcome(
    WidgetTester tester, {
    VoidCallback? onLogin,
    VoidCallback? onSignup,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: RangoTheme.light,
        home: WelcomeScreen(
          onLogin: onLogin ?? () {},
          onSignup: onSignup ?? () {},
        ),
      ),
    );
  }

  testWidgets('mostra o conteúdo do protótipo', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('r'), findsOneWidget);
    expect(find.text('rango'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Comida boa,\nentrega rápida.'), findsOneWidget);
    expect(
      find.text(
        'Os melhores restaurantes da sua região em poucos toques. '
        'Pediu, chegou.',
      ),
      findsOneWidget,
    );
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(
      find.text(
        'Ao continuar você aceita os Termos de uso e a Política de '
        'privacidade.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('os botões chamam as ações corretas', (tester) async {
    var logins = 0;
    var signups = 0;
    await pumpWelcome(
      tester,
      onLogin: () => logins++,
      onSignup: () => signups++,
    );

    await tester.tap(find.text('Entrar'));
    expect((logins, signups), (1, 0));

    await tester.tap(find.text('Criar conta'));
    expect((logins, signups), (1, 1));
  });

  testWidgets('tela pequena não estoura e mantém os botões', (tester) async {
    await pumpWelcome(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('Entrar').hitTestable(), findsOneWidget);
    expect(find.text('Criar conta').hitTestable(), findsOneWidget);
  });

  testWidgets('o app abre na Welcome', (tester) async {
    await tester.pumpWidget(const RangoApp());

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
