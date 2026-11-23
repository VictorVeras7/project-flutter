import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/ui/login/login_screen.dart';
import 'package:rango/ui/signup/signup_screen.dart';
import 'package:rango/ui/theme/rango_theme.dart';
import 'package:rango/ui/welcome/welcome_screen.dart';

void main() {
  void setSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Finder field(String hint) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  );

  Future<void> pumpLogin(
    WidgetTester tester, {
    ValueChanged<bool>? onSuccess,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: LoginScreen(
          onBack: () {},
          onLoginSuccess: onSuccess ?? (_) {},
          onForgotPassword: () {},
          onSignup: () {},
        ),
      ),
    );
  }

  Future<void> pumpSignup(
    WidgetTester tester, {
    VoidCallback? onSuccess,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: SignupScreen(
          onBack: () {},
          onSignupSuccess: onSuccess ?? () {},
          onLogin: () {},
        ),
      ),
    );
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    final button = find.byType(FilledButton);
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> fillSignup(WidgetTester tester) async {
    await tester.enterText(field('Maria Silva'), 'Marina Alves');
    await tester.enterText(field('voce@email.com'), 'marina.alves@email.com');
    await tester.enterText(field('(11) 90000-0000'), '(11) 98876-4410');
    await tester.enterText(field('Mínimo 6 caracteres'), 'rango123');
    await tester.enterText(field('Repita a senha'), 'rango123');
    await tester.pump();
  }

  group('Login', () {
    testWidgets('mostra o conteúdo do protótipo', (tester) async {
      await pumpLogin(tester);

      for (final text in [
        'Bem-vinda de volta',
        'Entre para continuar seus pedidos.',
        'E-mail',
        'Senha',
        'Manter conectado',
        'Esqueci minha senha',
        'Entrar',
        'Não tem conta?',
        'Criar conta',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Manter conectado começa marcado, como no protótipo.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('valida campos vazios e e-mail inválido', (tester) async {
      await pumpLogin(tester);

      await tapSubmit(tester);
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      expect(find.text('Informe sua senha.'), findsOneWidget);

      await tester.enterText(field('voce@email.com'), 'marina@email');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tapSubmit(tester);
      expect(find.text('E-mail inválido.'), findsOneWidget);
      expect(find.text('Informe sua senha.'), findsNothing);
    });

    testWidgets('senha incorreta mostra o erro', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'errada');

      await tapSubmit(tester);
      expect(find.text('Entrando...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Senha incorreta. Tente novamente.'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('senha correta passa por carregando e sucesso', (tester) async {
      bool? keepConnected;
      await pumpLogin(tester, onSuccess: (value) => keepConnected = value);
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tester.tap(find.text('Manter conectado'));

      await tapSubmit(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Bem-vinda!'), findsOneWidget);
      expect(keepConnected, isNull);

      await tester.pump(const Duration(milliseconds: 700));
      expect(keepConnected, isFalse);
    });

    testWidgets('alterna a visibilidade da senha', (tester) async {
      await pumpLogin(tester);
      bool obscured() =>
          tester.widget<TextField>(field('Sua senha')).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(obscured(), isFalse);
    });

    testWidgets('tela pequena não estoura', (tester) async {
      await pumpLogin(tester, size: const Size(320, 568));
      await tapSubmit(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('tema escuro renderiza sem erro', (tester) async {
      await pumpLogin(tester, theme: RangoTheme.dark);

      expect(tester.takeException(), isNull);
    });
  });

  group('Cadastro', () {
    testWidgets('mostra os cinco campos do protótipo', (tester) async {
      await pumpSignup(tester);

      for (final hint in [
        'Maria Silva',
        'voce@email.com',
        '(11) 90000-0000',
        'Mínimo 6 caracteres',
        'Repita a senha',
      ]) {
        expect(field(hint), findsOneWidget, reason: hint);
      }
      expect(find.text('Criar conta'), findsNWidgets(2));
      expect(find.text('Já tem conta?'), findsOneWidget);
    });

    testWidgets('mostra os erros de cada campo e pede os termos', (
      tester,
    ) async {
      await pumpSignup(tester);

      await tapSubmit(tester);
      for (final error in [
        'Informe seu nome completo.',
        'E-mail inválido.',
        'Telefone incompleto.',
        'Mínimo de 6 caracteres.',
        'As senhas não coincidem.',
        'Aceite os termos para continuar.',
      ]) {
        await tester.pump();
        expect(find.text(error), findsOneWidget, reason: error);
      }
    });

    testWidgets('não cria a conta sem aceitar os termos', (tester) async {
      var created = 0;
      await pumpSignup(tester, onSuccess: () => created++);
      await fillSignup(tester);

      await tapSubmit(tester);
      await tester.pump(const Duration(milliseconds: 1100));

      expect(created, 0);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(5));
    });

    testWidgets('cria a conta com dados válidos', (tester) async {
      var created = 0;
      await pumpSignup(tester, onSuccess: () => created++);
      await fillSignup(tester);
      final terms = find.textContaining('Li e aceito');
      await tester.ensureVisible(terms);
      await tester.pump();
      await tester.tap(terms);
      await tester.pump();

      await tapSubmit(tester);
      expect(find.text('Criando conta...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(created, 1);
    });

    testWidgets('tela pequena não estoura', (tester) async {
      await pumpSignup(tester, size: const Size(320, 568));
      await tapSubmit(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('tema escuro renderiza sem erro', (tester) async {
      await pumpSignup(tester, theme: RangoTheme.dark);

      expect(tester.takeException(), isNull);
    });
  });

  group('Navegação', () {
    testWidgets('segue a pilha do protótipo', (tester) async {
      setSize(tester, const Size(390, 844));
      await tester.pumpWidget(const RangoApp());

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      expect(find.byType(SignupScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('voltar do sistema retorna para a tela anterior', (
      tester,
    ) async {
      setSize(tester, const Size(390, 844));
      await tester.pumpWidget(const RangoApp());
      await tester.tap(find.text('Criar conta'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('sair durante o envio não gera erro', (tester) async {
      setSize(tester, const Size(390, 844));
      await tester.pumpWidget(const RangoApp());
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tapSubmit(tester);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
