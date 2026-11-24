import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/remote/api_models.dart';
import 'package:rango/ui/login/login_screen.dart';
import 'package:rango/ui/signup/signup_screen.dart';
import 'package:rango/ui/theme/rango_theme.dart';
import 'package:rango/ui/welcome/welcome_screen.dart';

import 'fake_backend.dart';

void main() {
  void setSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Finder field(String hint) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  );

  // Servidor de mentira: responde em 1 s e só aceita a senha da usuária de teste.
  Future<Map<String, String>> fakeLogin(
    String email,
    String password,
    bool keepConnected,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return password == 'rango123'
        ? const {}
        : const {'password': 'E-mail ou senha incorretos.'};
  }

  Future<Map<String, String>> fakeRegister(RegisterRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return const {};
  }

  Future<void> pumpLogin(
    WidgetTester tester, {
    Authenticate? authenticate,
    VoidCallback? onSuccess,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: LoginScreen(
          onBack: () {},
          authenticate: authenticate ?? fakeLogin,
          onLoginSuccess: onSuccess ?? () {},
          onForgotPassword: () {},
          onSignup: () {},
        ),
      ),
    );
  }

  Future<void> pumpSignup(
    WidgetTester tester, {
    Register? register,
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
          register: register ?? fakeRegister,
          onSignupSuccess: onSuccess ?? () {},
          onLogin: () {},
        ),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    setSize(tester, const Size(390, 844));
    setSavedSession(null);
    await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
    // Abertura: confere a sessão salva e cai na Welcome.
    await tester.pump();
    await tester.pump();
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

  Future<void> acceptTerms(WidgetTester tester) async {
    final terms = find.textContaining('Li e aceito');
    await tester.ensureVisible(terms);
    await tester.pump();
    await tester.tap(terms);
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

    testWidgets('erro do servidor aparece no campo da senha', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'errada');

      await tapSubmit(tester);
      expect(find.text('Entrando...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('senha correta passa por carregando e sucesso', (tester) async {
      bool? keepConnected;
      var successes = 0;
      await pumpLogin(
        tester,
        authenticate: (email, password, keep) {
          keepConnected = keep;
          return fakeLogin(email, password, keep);
        },
        onSuccess: () => successes++,
      );
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tester.tap(find.text('Manter conectado'));

      await tapSubmit(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Bem-vinda!'), findsOneWidget);
      expect(keepConnected, isFalse);
      expect(successes, 0);

      await tester.pump(const Duration(milliseconds: 700));
      expect(successes, 1);
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
      RegisterRequest? sent;
      await pumpSignup(
        tester,
        register: (request) {
          sent = request;
          return fakeRegister(request);
        },
        onSuccess: () => created++,
      );
      await fillSignup(tester);
      await acceptTerms(tester);

      await tapSubmit(tester);
      expect(find.text('Criando conta...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(created, 1);
      expect(sent?.toJson(), {
        'name': 'Marina Alves',
        'email': 'marina.alves@email.com',
        'phone': '(11) 98876-4410',
        'password': 'rango123',
        'passwordConfirmation': 'rango123',
        'acceptTerms': true,
        'keepSignedIn': true,
      });
    });

    testWidgets('erro do servidor aparece no campo e some ao editar', (
      tester,
    ) async {
      var created = 0;
      await pumpSignup(
        tester,
        register: (_) async => const {
          'email': 'Este e-mail já está cadastrado.',
        },
        onSuccess: () => created++,
      );
      await fillSignup(tester);
      await acceptTerms(tester);

      await tapSubmit(tester);
      await tester.pump();
      expect(created, 0);
      expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);

      await tester.enterText(field('voce@email.com'), 'nova@email.com');
      await tester.pump();
      expect(find.text('Este e-mail já está cadastrado.'), findsNothing);
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
      await pumpApp(tester);

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
      await pumpApp(tester);
      await tester.tap(find.text('Criar conta'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('sair durante o envio não gera erro', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.enterText(field('voce@email.com'), 'marina@email.com');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tapSubmit(tester);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
