import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/product.dart';
import 'package:rango/data/search.dart';
import 'package:rango/rango_store.dart';
import 'package:rango/ui/components/bottom_nav_bar.dart';
import 'package:rango/ui/components/product_card.dart';
import 'package:rango/ui/favorites/favorites_screen.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/product/product_screen.dart';
import 'package:rango/ui/search/search_screen.dart';
import 'package:rango/ui/theme/rango_theme.dart';

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

  Product item(
    String id,
    String name, {
    double price = 45,
    String restaurant = 'Forno di Napoli',
  }) => Product(
    id: id,
    name: name,
    restaurant: restaurant,
    category: 'Pizza',
    description: 'Descrição de $name',
    price: price,
    oldPrice: null,
    rating: 4.7,
    minMinutes: 30,
    maxMinutes: 40,
    hue: 20,
    tags: const {},
  );

  final pizzas = [
    item('p2', 'Pizza margherita'),
    item('p8', 'Pizza pepperoni', price: 49.9),
  ];

  Widget search({
    String query = '',
    SearchFilters filters = SearchFilters.none,
    List<Product>? results,
    List<String> recent = const ['pizza', 'açaí'],
    ValueChanged<String>? onPickTerm,
    ValueChanged<SearchFilters>? onApplyFilters,
    ValueChanged<SearchFilters>? onChangeFilters,
    VoidCallback? onClearRecent,
  }) => SearchScreen(
    query: query,
    filters: filters,
    idle: query.isEmpty && filters.isEmpty,
    results: results,
    total: results?.length ?? 0,
    recent: recent,
    suggestions: const [
      SearchSuggestion('Pizza margherita', 'Forno di Napoli · 4,7 · R\$ 45,00'),
      SearchSuggestion('Combo burger + fritas'),
    ],
    categories: const ['Todos', 'Pizza', 'Massas'],
    favoriteIds: const {'p2'},
    onQueryChanged: (_) {},
    onSubmit: () {},
    onPickTerm: onPickTerm ?? (_) {},
    onClearRecent: onClearRecent ?? () {},
    onApplyFilters: onApplyFilters ?? (_) {},
    onChangeFilters: onChangeFilters ?? (_) {},
    onOpenProduct: (_) {},
    onToggleFavorite: (_) {},
    onAddToCart: (_) {},
  );

  Widget favoritesScreen(List<Product>? list, {VoidCallback? onExplore}) =>
      FavoritesScreen(
        favorites: list,
        onLoad: () {},
        onOpenProduct: (_) {},
        onRemove: (_) {},
        onAddToCart: (_) {},
        onExplore: onExplore ?? () {},
      );

  group('Filtros', () {
    test('conta só o que foge do padrão e monta os chips', () {
      const filters = SearchFilters(
        category: 'Pizza',
        maxPrice: 45,
        minRating: 4.5,
        sort: SearchSort.priceAsc,
      );
      expect(SearchFilters.none.activeCount, 0);
      expect(filters.activeCount, 4);
      expect(
        [for (final (label, _) in filters.chips) label],
        ['Pizza', 'até R\$ 45,00', '4,5+ estrelas', 'Menor preço'],
      );
      // Cada chip remove só o próprio filtro.
      final (_, withoutPrice) = filters.chips[1];
      expect(withoutPrice.hasPrice, isFalse);
      expect(withoutPrice.activeCount, 3);
    });

    test('"Ver tudo" de cada seção usa os filtros do protótipo', () {
      expect(
        SearchFilters.forSection(ProductTag.offer).sort,
        SearchSort.priceAsc,
      );
      expect(
        SearchFilters.forSection(ProductTag.popular).sort,
        SearchSort.rating,
      );
      expect(
        SearchFilters.forSection(ProductTag.recommended),
        const SearchFilters(minRating: 4.5, sort: SearchSort.rating),
      );
      expect(SearchFilters.forSection(ProductTag.fast).maxTime, 30);
    });

    test('contadores no singular e no plural', () {
      expect(resultCountLabel(1), '1 resultado');
      expect(resultCountLabel(3), '3 resultados');
      expect(savedCountLabel(1), '1 item salvo');
      expect(savedCountLabel(2), '2 itens salvos');
    });
  });

  group('Tela de busca', () {
    testWidgets('sem termo mostra recentes e sugestões', (tester) async {
      String? picked;
      await pumpScreen(tester, search(onPickTerm: (t) => picked = t));

      for (final text in [
        'Buscas recentes',
        'Limpar',
        'pizza',
        'açaí',
        'Sugestões para você',
        'Forno di Napoli · 4,7 · R\$ 45,00',
        'Combo burger + fritas',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      await tester.tap(find.text('açaí'));
      await tester.pump();
      expect(picked, 'açaí');
      // O termo tocado vai para o campo.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'açaí',
      );
    });

    testWidgets('sem buscas recentes avisa', (tester) async {
      await pumpScreen(tester, search(recent: const []));
      expect(find.text('Nenhuma busca recente.'), findsOneWidget);
      expect(find.text('Limpar'), findsNothing);
    });

    testWidgets('resultados com contagem, ordenação, chips e badge', (
      tester,
    ) async {
      SearchFilters? changed;
      await pumpScreen(
        tester,
        search(
          query: 'pizza',
          filters: const SearchFilters(maxTime: 30, sort: SearchSort.rating),
          results: pizzas,
          onChangeFilters: (f) => changed = f,
        ),
      );

      expect(find.text('2 resultados'), findsOneWidget);
      // Ordenação no título e no chip.
      expect(find.text('Melhor avaliados'), findsNWidgets(2));
      expect(find.text('Forno di Napoli · Pizza'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Filtros, 2 ativos'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Remover filtro até 30 min'));
      expect(changed, const SearchFilters(sort: SearchSort.rating));
    });

    testWidgets('sem resultados oferece limpar os filtros', (tester) async {
      SearchFilters? changed;
      await pumpScreen(
        tester,
        search(
          query: 'sushi',
          filters: const SearchFilters(maxPrice: 20),
          results: const [],
          onChangeFilters: (f) => changed = f,
        ),
      );

      expect(find.text('Nenhum produto encontrado.'), findsOneWidget);
      expect(
        find.text('Tente outro termo ou ajuste os filtros aplicados.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Limpar filtros'));
      expect(changed, SearchFilters.none);
    });

    testWidgets('carregando mostra o indicador', (tester) async {
      await pumpScreen(tester, search(query: 'pizza'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('folha de filtros aplica o rascunho e fechar descarta', (
      tester,
    ) async {
      final applied = <SearchFilters>[];
      await pumpScreen(tester, search(onApplyFilters: applied.add));

      await tester.tap(find.bySemanticsLabel('Filtros'));
      await tester.pumpAndSettle();
      for (final text in [
        'Categoria',
        'Faixa de preço',
        'até R\$ 80,00',
        'R\$ 10',
        'R\$ 80',
        'Avaliação mínima',
        'Tempo de entrega',
        'Ordenar por',
        'Preço · crescente',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      await tester.tap(find.text('Massas'));
      await tester.tap(find.text('4,8+'));
      await tester.tap(find.text('até 25 min'));
      await tester.tap(find.text('Preço · decrescente'));
      await tester.pump();
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(
        applied.single,
        const SearchFilters(
          category: 'Massas',
          minRating: 4.8,
          maxTime: 25,
          sort: SearchSort.priceDesc,
        ),
      );

      // Fechar não aplica nada.
      await tester.tap(find.bySemanticsLabel('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pizza'));
      await tester.tap(find.bySemanticsLabel('Fechar filtros'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(1));
    });

    testWidgets('fechar a folha não reabre o teclado', (tester) async {
      await pumpScreen(tester, search());

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.bySemanticsLabel('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Fechar filtros'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
      final focused = FocusManager.instance.primaryFocus?.context?.widget;
      expect(focused, isNot(isA<EditableText>()));
    });

    testWidgets('"Limpar filtros" da folha volta ao padrão', (tester) async {
      final applied = <SearchFilters>[];
      await pumpScreen(
        tester,
        search(
          query: 'pizza',
          filters: const SearchFilters(maxPrice: 30, minRating: 4),
          results: pizzas,
          onApplyFilters: applied.add,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Filtros, 2 ativos'));
      await tester.pumpAndSettle();
      expect(find.text('até R\$ 30,00'), findsNWidgets(2));
      await tester.tap(find.text('Limpar filtros'));
      await tester.pump();
      expect(find.text('até R\$ 80,00'), findsOneWidget);
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(applied.single, SearchFilters.none);
    });

    testWidgets('cabe em tela estreita e no tema escuro', (tester) async {
      await pumpScreen(
        tester,
        search(
          query: 'pizza',
          filters: const SearchFilters(
            category: 'Pizza',
            maxPrice: 45,
            minRating: 4.5,
            maxTime: 30,
            sort: SearchSort.priceDesc,
          ),
          results: pizzas,
        ),
        size: const Size(320, 640),
        theme: RangoTheme.dark,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Filtros, 5 ativos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Tela de favoritos', () {
    testWidgets('lista com contador, coração e "Adicionar"', (tester) async {
      await pumpScreen(tester, favoritesScreen(pizzas));

      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.text('2 itens salvos'), findsOneWidget);
      expect(find.text('Pizza pepperoni'), findsOneWidget);
      expect(find.text('Forno di Napoli · Pizza'), findsNWidgets(2));
      expect(find.text('Adicionar'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Remover dos favoritos'), findsNWidgets(2));

      // "Adicionar" encosta na direita, alinhado com o coração.
      final heart = tester.getTopRight(
        find.byIcon(Icons.favorite_rounded).first,
      );
      final button = tester.getTopRight(find.byType(FilledButton).first);
      expect(button.dx, moreOrLessEquals(heart.dx, epsilon: 1));
    });

    testWidgets('vazio leva a explorar produtos', (tester) async {
      var explored = false;
      await pumpScreen(
        tester,
        favoritesScreen(const [], onExplore: () => explored = true),
      );

      expect(find.text('0 itens salvos'), findsOneWidget);
      expect(find.text('Nenhum favorito ainda'), findsOneWidget);
      await tester.tap(find.text('Explorar produtos'));
      expect(explored, isTrue);
    });

    testWidgets('cabe em tela estreita e no tema escuro', (tester) async {
      await pumpScreen(
        tester,
        favoritesScreen([
          item('p1', 'Burger duplo cheddar com bacon e cebola caramelizada'),
          ...pizzas,
        ]),
        size: const Size(320, 640),
        theme: RangoTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Busca e favoritos com o back-end', () {
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

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    testWidgets('digitar busca uma vez só, depois de 300 ms', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Buscas recentes'), findsOneWidget);
      // Sugestão com o resumo do produto que a Home já trouxe.
      expect(
        find.text('Casa do Burger · 4,8 · R\$ 30,00'),
        findsAtLeastNWidgets(1),
      );

      for (final text in ['m', 'ma', 'mar', 'margherita']) {
        await type(tester, text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(backend.productQueries, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);

      expect(backend.productQueries.single['q'], 'margherita');
      expect(backend.productQueries.single['sort'], 'relevance');
      expect(find.text('1 resultado'), findsOneWidget);
      expect(find.text('Pizza margherita'), findsOneWidget);

      // Apagar o termo volta para recentes e sugestões, sem nova busca.
      await tester.tap(find.bySemanticsLabel('Limpar busca'));
      await settle(tester);
      expect(find.text('Buscas recentes'), findsOneWidget);
      expect(backend.productQueries, hasLength(1));
    });

    testWidgets('abrir um produto guarda a busca; voltar mantém tudo', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      await type(tester, 'Lasanha');
      await tester.pump(RangoStore.searchDelay);
      await settle(tester);
      expect(find.text('Cantina Nonna · Massas'), findsOneWidget);

      await tester.tap(find.text('Lasanha bolonhesa'));
      await settle(tester);
      expect(find.byType(ProductScreen), findsOneWidget);
      expect(backend.recent.first, 'lasanha');

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Lasanha bolonhesa'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Lasanha',
      );

      // Voltar da busca leva ao Início.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('"Buscar" do teclado guarda o termo', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      await type(tester, 'Brownie ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);

      expect(backend.recent.first, 'brownie');
      expect(backend.productQueries.single['q'], 'Brownie');
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('busca recente tocada busca na hora', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      await tester.tap(find.text('burger'));
      await settle(tester);

      expect(backend.productQueries.single['q'], 'burger');
      expect(find.text('Burger duplo cheddar'), findsOneWidget);
    });

    testWidgets('"Ver tudo" abre a busca com os filtros da seção', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      // Primeira seção: "Ofertas para você", do menor preço.
      await tester.tap(find.text('Ver tudo').first);
      await settle(tester);

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(backend.productQueries.single['sort'], 'price_asc');
      expect(find.text('4 resultados'), findsOneWidget);
      expect(find.text('Menor preço'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Filtros, 1 ativo'), findsOneWidget);

      // A Lasanha (R$ 52) é a mais cara: fica por último.
      final names = [
        for (final text in tester.widgetList<Text>(find.byType(Text)))
          if (text.data case final data?
              when data.startsWith('Pizza') || data.startsWith('Lasanha'))
            data,
      ];
      expect(names.last, 'Lasanha bolonhesa');
    });

    testWidgets('filtros aplicados vão para o servidor', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pizza').last);
      await tester.tap(find.text('4,8+'));
      await tester.tap(find.text('até 30 min'));
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Filtros aplicados.'), findsOneWidget);
      expect(backend.productQueries.single, {
        'category': 'pizza',
        'minRating': '4.8',
        'maxDeliveryTime': '30',
        'sort': 'relevance',
        'pageSize': '50',
      });
      // Nenhum produto entrega em até 30 min no back-end falso.
      expect(find.text('Nenhum produto encontrado.'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros'));
      await settle(tester);
      expect(find.text('Buscas recentes'), findsOneWidget);
    });

    testWidgets('"Limpar" recentes volta a lista se o servidor recusar', (
      tester,
    ) async {
      final backend = FakeBackend()..failRecentClear = true;
      await pumpLoggedIn(tester, backend: backend);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      await tester.tap(find.text('Limpar'));
      await settle(tester);
      expect(find.text('Não foi possível limpar.'), findsOneWidget);
      expect(find.text('açaí'), findsOneWidget);

      backend.failRecentClear = false;
      await tester.tap(find.text('Limpar'));
      await settle(tester);
      expect(find.text('Nenhuma busca recente.'), findsOneWidget);
      expect(backend.recent, isEmpty);
    });

    testWidgets('com o teclado aberto a barra inferior some', (tester) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      expect(find.byType(BottomNavBar), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(find.byType(BottomNavBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('favoritos: mais recentes primeiro, remover e badge', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);
      expect(find.bySemanticsLabel('Favoritos, 1'), findsOneWidget);

      // Favorita o Brownie na Home; ele entra no topo da lista.
      final heart = find.descendant(
        of: find.ancestor(
          of: find.text('Brownie com sorvete'),
          matching: find.byType(ProductTile),
        ),
        matching: find.byTooltip('Adicionar aos favoritos'),
      );
      await tester.ensureVisible(heart);
      await tester.tap(heart);
      await settle(tester);
      expect(backend.favorites, {'p2', 'p5'});
      expect(find.bySemanticsLabel('Favoritos, 2'), findsOneWidget);

      await tester.tap(find.text('Favoritos'));
      await settle(tester);
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('2 itens salvos'), findsOneWidget);
      final first = tester.getTopLeft(find.text('Brownie com sorvete')).dy;
      final second = tester.getTopLeft(find.text('Pizza margherita')).dy;
      expect(first, lessThan(second));

      // Remover pelo coração tira da lista na hora.
      await tester.tap(find.bySemanticsLabel('Remover dos favoritos').first);
      await settle(tester);
      expect(find.text('Removido dos favoritos.'), findsOneWidget);
      expect(find.text('Brownie com sorvete'), findsNothing);
      expect(find.text('1 item salvo'), findsOneWidget);
      expect(backend.favorites, {'p2'});

      await tester.tap(find.bySemanticsLabel('Remover dos favoritos'));
      await settle(tester);
      expect(find.text('Nenhum favorito ainda'), findsOneWidget);

      await tester.tap(find.text('Explorar produtos'));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('favorito aberto e "Adicionar" ao carrinho', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Favoritos'));
      await settle(tester);
      await tester.tap(find.text('Adicionar'));
      await settle(tester);
      expect(backend.cart.single.productId, 'p2');
      expect(find.text('Produto adicionado ao carrinho.'), findsOneWidget);

      await tester.tap(find.text('Pizza margherita'));
      await settle(tester);
      expect(find.byType(ProductScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });
  });
}
