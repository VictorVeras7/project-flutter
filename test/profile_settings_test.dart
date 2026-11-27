import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rango/app.dart';
import 'package:rango/data/profile.dart';
import 'package:rango/ui/checkout/address_screen.dart';
import 'package:rango/ui/checkout/payment_screen.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/profile/profile_screen.dart';
import 'package:rango/ui/settings/settings_screen.dart';
import 'package:rango/ui/theme/rango_theme.dart';
import 'package:rango/ui/welcome/welcome_screen.dart';

import 'fake_backend.dart';

void main() {
  void setSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(theme: theme ?? RangoTheme.light, home: screen),
    );
  }

  const marina = Profile(
    name: 'Marina Alves',
    email: 'marina.alves@email.com',
    phone: '(11) 98876-4410',
  );

  Widget profileScreen({
    Profile? profile = marina,
    int unread = 12,
    VoidCallback? onLogout,
  }) => ProfileScreen(
    profile: profile,
    unreadCount: unread,
    addressCount: 2,
    paymentCount: 4,
    theme: ThemePreference.dark,
    onLoad: () {},
    onOpenNotifications: () {},
    onEditProfile: () {},
    onAddresses: () {},
    onPayments: () {},
    onSettings: () {},
    onTheme: () {},
    onHelp: () {},
    onLogout: onLogout ?? () {},
  );

  group('Textos do perfil', () {
    test('dicas no singular e no plural', () {
      expect(addressCountLabel(1), '1 salvo');
      expect(addressCountLabel(2), '2 salvos');
      expect(paymentCountLabel(1), '1 método disponível');
      expect(paymentCountLabel(4), '4 métodos disponíveis');
      expect(unreadLabel(0), 'tudo lido');
      expect(unreadLabel(1), '1 não lida');
      expect(unreadLabel(12), '12 não lidas');
    });

    test('iniciais do primeiro nome e tema desconhecido vira claro', () {
      expect(avatarInitials('Marina Alves'), 'MA');
      expect(avatarInitials('  joão'), 'JO');
      expect(ThemePreference.fromApi('dark'), ThemePreference.dark);
      expect(ThemePreference.fromApi('sepia'), ThemePreference.light);
    });

    test('preferências trocam uma chave só', () {
      final prefs = NotificationPrefs.initial.copyWith(
        NotificationTopic.news,
        true,
      );
      expect(prefs.toJson(), {'orders': true, 'promos': true, 'news': true});
      expect(prefs[NotificationTopic.promos], isTrue);
    });
  });

  group('Tela de perfil', () {
    testWidgets('dados da conta e linhas com dicas', (tester) async {
      var loggedOut = false;
      await pumpScreen(tester, profileScreen(onLogout: () => loggedOut = true));

      for (final text in [
        'Perfil',
        'MA',
        'Marina Alves',
        'marina.alves@email.com',
        '(11) 98876-4410',
        'nome, e-mail e telefone',
        '2 salvos',
        '4 métodos disponíveis',
        'Configurações',
        '12 não lidas',
        'Escuro',
        'Ajuda',
        'Sair da conta',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // "Editar perfil" no botão e na primeira linha.
      expect(find.text('Editar perfil'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Notificações não lidas'), findsOneWidget);

      // "Sair da conta" em vermelho e sem seta.
      final logout = tester.widget<Text>(find.text('Sair da conta'));
      expect(logout.style!.color, RangoColors.error);
      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da conta'));
      expect(loggedOut, isTrue);
    });

    testWidgets('tudo lido não mostra o ponto no sino', (tester) async {
      await pumpScreen(tester, profileScreen(unread: 0));
      expect(find.text('tudo lido'), findsOneWidget);
      expect(find.bySemanticsLabel('Notificações'), findsOneWidget);
    });

    testWidgets('carregando mostra o indicador', (tester) async {
      await pumpScreen(tester, profileScreen(profile: null));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('cabe em tela estreita e no tema escuro', (tester) async {
      await pumpScreen(
        tester,
        profileScreen(),
        size: const Size(320, 640),
        theme: RangoTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Telas de configurações', () {
    Widget settingsScreen({VoidCallback? onSync}) => SettingsScreen(
      theme: ThemePreference.system,
      onBack: () {},
      onTheme: () {},
      onNotifications: () {},
      onLanguage: () {},
      onPersonalData: () {},
      onAddresses: () {},
      onPayments: () {},
      onSync: onSync ?? () {},
      onClearData: () {},
      onHelp: () {},
      onTerms: () {},
    );

    testWidgets('Configurações tem os quatro grupos e a versão', (
      tester,
    ) async {
      await pumpScreen(tester, settingsScreen());

      for (final text in [
        'PREFERÊNCIAS',
        'CONTA',
        'DADOS E CONEXÃO',
        'SOBRE',
        'Sistema',
        'Português',
        'Dados pessoais',
        'Sincronizar agora',
        'Limpar dados locais',
        'Central de ajuda',
        'Termos e privacidade',
        'rango v1.0.0 · build 2026.08',
      ]) {
        await tester.dragUntilVisible(
          find.text(text),
          find.byType(ListView),
          const Offset(0, -120),
        );
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final clear = tester.widget<Text>(find.text('Limpar dados locais'));
      expect(clear.style!.color, RangoColors.error);
    });

    testWidgets('Tema marca a opção e, em "Sistema", segue o aparelho', (
      tester,
    ) async {
      ThemePreference? picked;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpScreen(
        tester,
        ThemeScreen(
          theme: ThemePreference.system,
          onBack: () {},
          onSelect: (t) => picked = t,
        ),
      );

      expect(find.text('Usar configuração do sistema'), findsOneWidget);
      expect(find.text('Segue o tema do smartphone'), findsOneWidget);
      // Aparelho escuro: a miniatura "Escuro" fica com a borda laranja.
      BoxBorder border(String name) =>
          (tester
                      .widget<Container>(
                        find
                            .ancestor(
                              of: find.text(name),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration)
              .border!;
      expect((border('Escuro') as Border).top.color, RangoColors.primary);
      expect((border('Claro') as Border).top.color, isNot(RangoColors.primary));

      await tester.tap(find.text('Claro').last);
      expect(picked, ThemePreference.light);
    });

    testWidgets('Notificações liga e desliga cada aviso', (tester) async {
      final toggled = <(NotificationTopic, bool)>[];
      await pumpScreen(
        tester,
        NotificationSettingsScreen(
          prefs: NotificationPrefs.initial,
          onBack: () {},
          onToggle: (topic, on) => toggled.add((topic, on)),
        ),
      );

      expect(find.text('Cupons e ofertas exclusivas'), findsOneWidget);
      await tester.tap(find.text('Novidades'));
      await tester.tap(find.text('Pedidos'));
      expect(toggled, [
        (NotificationTopic.news, true),
        (NotificationTopic.orders, false),
      ]);
    });

    testWidgets('cabem em tela estreita e no tema escuro', (tester) async {
      await pumpScreen(
        tester,
        settingsScreen(),
        size: const Size(320, 640),
        theme: RangoTheme.dark,
      );
      expect(tester.takeException(), isNull);

      await pumpScreen(
        tester,
        ThemeScreen(
          theme: ThemePreference.dark,
          onBack: () {},
          onSelect: (_) {},
        ),
        size: const Size(320, 640),
        theme: RangoTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Perfil e configurações com o back-end', () {
    Future<FakeBackend> pumpLoggedIn(
      WidgetTester tester, {
      FakeBackend? backend,
    }) async {
      setSize(tester, const Size(390, 844));
      setSavedSession('refresh-1');
      final server = backend ?? FakeBackend();
      await tester.pumpWidget(RangoApp(api: server.api()));
      await settle(tester);
      return server;
    }

    Brightness appBrightness(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

    SystemUiOverlayStyle statusBar(WidgetTester tester) => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
        )
        .value;

    Future<void> openProfile(WidgetTester tester) async {
      await tester.tap(find.text('Perfil'));
      await settle(tester);
    }

    // A lista já monta os itens fora da tela; é preciso rolar até eles.
    Future<void> scrollTo(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('aba Perfil com os dados do servidor', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await openProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
      for (final text in [
        'Marina Alves',
        '(11) 98876-4410',
        '2 salvos',
        '3 métodos disponíveis',
        '12 não lidas',
        'Claro',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(backend.requests, contains('GET /me'));

      // Endereços abre a tela do checkout e volta para o Perfil.
      await tester.tap(find.text('Endereços'));
      await settle(tester);
      expect(find.byType(AddressScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Voltar do Perfil leva ao Início.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('avatar da Home abre o Perfil', (tester) async {
      await pumpLoggedIn(tester);
      await tester.tap(find.byTooltip('Perfil'));
      await settle(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('tema escolhido vale no app todo e na barra de status', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);
      expect(appBrightness(tester), Brightness.light);
      expect(statusBar(tester), SystemUiOverlayStyle.dark);

      await openProfile(tester);
      await tester.tap(find.text('Tema'));
      await settle(tester);
      expect(find.byType(ThemeScreen), findsOneWidget);
      await tester.tap(find.text('Escuro').last);
      await tester.pumpAndSettle();

      expect(backend.settingsPatches.single, {'theme': 'dark'});
      expect(appBrightness(tester), Brightness.dark);
      expect(statusBar(tester), SystemUiOverlayStyle.light);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('tema salvo vale desde a abertura', (tester) async {
      await pumpLoggedIn(tester, backend: FakeBackend()..theme = 'dark');
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(appBrightness(tester), Brightness.dark);
    });

    testWidgets('tema recusado volta ao anterior com aviso', (tester) async {
      final backend = FakeBackend()..failSettings = true;
      await pumpLoggedIn(tester, backend: backend);

      await openProfile(tester);
      await tester.tap(find.text('Tema'));
      await settle(tester);
      await tester.tap(find.text('Escuro').last);
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível salvar.'), findsOneWidget);
      expect(appBrightness(tester), Brightness.light);
    });

    testWidgets('notificações mandam só a chave trocada', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await openProfile(tester);
      await tester.tap(find.text('Configurações'));
      await settle(tester);
      await tester.tap(find.text('Notificações'));
      await settle(tester);
      await tester.tap(find.text('Novidades'));
      await settle(tester);

      expect(backend.settingsPatches.single, {
        'notifications': {'news': true},
      });
      expect(backend.notifications['news'], isTrue);
      final news = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(AnimatedContainer).last,
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(news.properties.toggled, isTrue);

      // Recusada: volta a desligada.
      backend.failSettings = true;
      await tester.tap(find.text('Novidades'));
      await settle(tester);
      expect(find.text('Não foi possível salvar.'), findsOneWidget);
      expect(backend.notifications['news'], isTrue);
      final again = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(AnimatedContainer).last,
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(again.properties.toggled, isTrue);
    });

    testWidgets('sair apaga a sessão e revoga o token', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await openProfile(tester);
      await scrollTo(tester, 'Sair da conta');
      await tester.tap(find.text('Sair da conta'));
      await settle(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Você saiu da conta.'), findsOneWidget);
      expect(backend.loggedOut, ['refresh-1']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('refresh_token'), isNull);
    });

    testWidgets('limpar dados locais sai e volta ao tema claro', (
      tester,
    ) async {
      await pumpLoggedIn(tester, backend: FakeBackend()..theme = 'dark');
      await tester.pumpAndSettle();
      expect(appBrightness(tester), Brightness.dark);

      await openProfile(tester);
      await tester.tap(find.text('Configurações'));
      await settle(tester);
      await scrollTo(tester, 'Limpar dados locais');
      await tester.tap(find.text('Limpar dados locais'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Dados locais apagados.'), findsOneWidget);
      expect(appBrightness(tester), Brightness.light);
    });

    testWidgets('sincronizar confirma e pagamento volta às configurações', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      await openProfile(tester);
      await tester.tap(find.text('Configurações'));
      await settle(tester);
      backend.requests.clear();
      await tester.tap(find.text('Sincronizar agora'));
      await settle(tester);
      expect(find.text('Dados sincronizados.'), findsOneWidget);
      expect(
        backend.requests,
        containsAll(['GET /home', 'GET /cart', 'GET /orders', 'GET /me']),
      );

      await tester.tap(find.text('Formas de pagamento'));
      await settle(tester);
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('opções sem tela avisam "em breve"', (tester) async {
      await pumpLoggedIn(tester);

      await openProfile(tester);
      await tester.tap(find.text('Editar perfil').first);
      await settle(tester);
      expect(
        find.text('Editar perfil estará disponível em breve.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Configurações'));
      await settle(tester);
      await tester.tap(find.text('Idioma'));
      await settle(tester);
      expect(
        find.text('Por enquanto, o app está disponível apenas em português.'),
        findsOneWidget,
      );
    });
  });
}
