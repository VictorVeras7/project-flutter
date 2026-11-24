import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/product.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/login/login_screen.dart';
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  // Abre o app já logado, com a sessão salva no aparelho.
  Future<FakeBackend> pumpLoggedIn(
    WidgetTester tester, {
    FakeBackend? backend,
    Size size = const Size(390, 844),
  }) async {
    setSize(tester, size);
    setSavedSession('refresh-1');
    final server = backend ?? FakeBackend();
    await tester.pumpWidget(RangoApp(api: server.api()));
    await settle(tester);
    return server;
  }

  const sample = Product(
    id: 'p1',
    name: 'Burger duplo cheddar',
    restaurant: 'Casa do Burger',
    category: 'Hambúrguer',
    description: 'Dois blends de 120g',
    price: 34.9,
    oldPrice: 42.9,
    rating: 4.8,
    minMinutes: 25,
    maxMinutes: 35,
    hue: 48,
    tags: {ProductTag.offer},
  );

  Future<void> pumpHome(
    WidgetTester tester, {
    bool loading = false,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: HomeScreen(
          userName: 'Marina Alves',
          address: 'Rua das Palmeiras, 128',
          cartCount: 2,
          hasUnread: true,
          loading: loading,
          categories: const ['Todos', 'Hambúrguer'],
          sections: const {
            ProductTag.offer: [sample],
            ProductTag.popular: [sample],
            ProductTag.recommended: [sample],
            ProductTag.fast: [sample],
          },
          categoryProducts: const {
            'Hambúrguer': [sample],
          },
          favoriteIds: const {'p1'},
          onCategoryChange: (_) {},
          onToggleFavorite: (_) {},
          onAddToCart: (_) {},
          onOpenProduct: (_) {},
          onOpenCart: () {},
          onOpenNotifications: () {},
          onOpenSearch: () {},
          onOpenProfile: () {},
          onOpenAddress: () {},
          onSeeAll: (_) {},
        ),
      ),
    );
  }

  group('Home', () {
    testWidgets('mostra o conteúdo do protótipo', (tester) async {
      await pumpHome(tester);

      for (final text in [
        'MA',
        'Olá, Marina',
        'Rua das Palmeiras, 128',
        'O que você quer comer hoje?',
        'Todos',
        'Hambúrguer',
        'SÓ HOJE',
        '20% OFF acima\nde R\$ 40',
        'RANGO10',
        'Ofertas para você',
        'Mais pedidos',
        'Recomendados',
        'Entrega rápida',
        '2',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.text('Ver tudo'), findsNWidgets(4));
      expect(find.text('R\$ 34,90'), findsWidgets);
      expect(find.text('R\$ 42,90'), findsWidgets);
      expect(find.text('4,8'), findsWidgets);
      expect(find.text('25-35 min'), findsWidgets);
      expect(find.text('OFERTA'), findsWidgets);
    });

    testWidgets('mostra o skeleton enquanto carrega', (tester) async {
      await pumpHome(tester, loading: true);

      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      expect(find.text('Ofertas para você'), findsNothing);
    });

    testWidgets('categoria troca as seções pela lista', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Hambúrguer'));
      await tester.pump();

      expect(find.text('1 itens'), findsOneWidget);
      expect(find.text('Ofertas para você'), findsNothing);
      expect(find.text('Dois blends de 120g'), findsOneWidget);
    });

    for (final (name, size, theme) in [
      ('tela pequena não estoura', const Size(320, 568), RangoTheme.light),
      ('tema escuro renderiza sem erro', const Size(390, 844), RangoTheme.dark),
    ]) {
      testWidgets(name, (tester) async {
        await pumpHome(tester, size: size, theme: theme);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Hambúrguer'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Integração com o back-end', () {
    testWidgets('login leva para a Home com os dados do servidor', (
      tester,
    ) async {
      setSize(tester, const Size(390, 844));
      setSavedSession(null);
      final backend = FakeBackend(homeDelay: const Duration(seconds: 1));
      await tester.pumpWidget(RangoApp(api: backend.api()));
      await settle(tester);

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.enterText(field('voce@email.com'), 'marina.alves@email.com');
      await tester.enterText(field('Sua senha'), 'rango123');
      await tester.tap(find.byType(FilledButton));
      await settle(tester);
      expect(find.text('Bem-vinda!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.text('Olá, Marina'), findsOneWidget);
      expect(find.text('Burger duplo cheddar'), findsWidgets);
      expect(
        backend.requests,
        containsAllInOrder(['POST /auth/login', 'GET /home']),
      );
    });

    testWidgets('senha errada mostra a mensagem do servidor', (tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession(null);
      await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
      await settle(tester);

      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.enterText(field('voce@email.com'), 'marina.alves@email.com');
      await tester.enterText(field('Sua senha'), 'errada');
      await tester.tap(find.byType(FilledButton));
      await settle(tester);

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('cadastro com e-mail em uso marca o campo', (tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession(null);
      await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
      await settle(tester);

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.enterText(field('Maria Silva'), 'Marina Alves');
      await tester.enterText(field('voce@email.com'), 'marina.alves@email.com');
      await tester.enterText(field('(11) 90000-0000'), '(11) 98876-4410');
      await tester.enterText(field('Mínimo 6 caracteres'), 'rango123');
      await tester.enterText(field('Repita a senha'), 'rango123');
      final terms = find.textContaining('Li e aceito');
      await tester.ensureVisible(terms);
      await tester.pump();
      await tester.tap(terms);
      final button = find.byType(FilledButton);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);

      expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
    });

    testWidgets('cadastro novo entra na Home com o aviso', (tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession(null);
      await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
      await settle(tester);

      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.enterText(field('Maria Silva'), 'Ana Lima');
      await tester.enterText(field('voce@email.com'), 'ana@email.com');
      await tester.enterText(field('(11) 90000-0000'), '(11) 99999-8888');
      await tester.enterText(field('Mínimo 6 caracteres'), 'abc123');
      await tester.enterText(field('Repita a senha'), 'abc123');
      final terms = find.textContaining('Li e aceito');
      await tester.ensureVisible(terms);
      await tester.pump();
      await tester.tap(terms);
      final button = find.byType(FilledButton);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Conta criada com sucesso!'), findsOneWidget);
    });

    testWidgets('sessão salva abre direto na Home', (tester) async {
      final backend = await pumpLoggedIn(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(backend.requests.first, 'POST /auth/refresh');
    });

    testWidgets('sessão salva inválida abre na Welcome', (tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession('vencido');
      await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
      await settle(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('favoritar e adicionar falam com o servidor', (tester) async {
      final backend = await pumpLoggedIn(tester);

      // p2 já é favorito no servidor; p1 não.
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
      await tester.tap(find.byTooltip('Adicionar aos favoritos').first);
      await settle(tester);
      expect(find.text('Adicionado aos favoritos.'), findsOneWidget);
      expect(backend.favorites, contains('p1'));

      await tester.tap(find.byTooltip('Adicionar ao carrinho').first);
      await settle(tester);
      expect(find.text('Produto adicionado ao carrinho.'), findsOneWidget);
      expect(backend.cartCount, 1);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('chip de categoria busca os produtos no servidor', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Bebidas'));
      await settle(tester);

      expect(backend.requests.last, 'GET /products');
      expect(find.text('1 itens'), findsOneWidget);
      expect(find.text('Brownie com sorvete'), findsOneWidget);
    });

    testWidgets('sessão encerrada no servidor volta para o login', (
      tester,
    ) async {
      final backend = FakeBackend()..expireNextHome = true;
      await pumpLoggedIn(tester, backend: backend);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sua sessão expirou. Entre novamente.'), findsOneWidget);
    });
  });
}
