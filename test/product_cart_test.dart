import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/cart.dart';
import 'package:rango/data/product.dart';
import 'package:rango/ui/cart/cart_screen.dart';
import 'package:rango/ui/components/product_card.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/product/product_screen.dart';
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  const sample = Product(
    id: 'p1',
    name: 'Burger duplo cheddar com bacon e molho especial',
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

  const detail = ProductDetail(
    product: sample,
    ingredients: 'Pão brioche, 2 blends de 120g. Molho da casa.',
    addons: [
      Addon(id: 'a1', name: 'Bacon extra', price: 4),
      Addon(id: 'a4', name: 'Refrigerante 350ml', price: 7),
    ],
  );

  Future<void> pumpProduct(
    WidgetTester tester, {
    ProductDetail? productDetail = detail,
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: ProductScreen(
          preview: sample,
          detail: productDetail,
          favorite: true,
          onBack: () {},
          onToggleFavorite: (_) {},
          onAdd: (_, {quantity = 1, addonIds = const [], notes = ''}) async =>
              true,
        ),
      ),
    );
  }

  const cart = Cart(
    lines: [
      CartLine(
        id: 1,
        productId: 'p1',
        name: 'Burger duplo cheddar com bacon e molho especial',
        hue: 48,
        quantity: 12,
        addons: ['Bacon extra', 'Refrigerante 350ml'],
        notes: 'sem cebola, ponto da carne bem passado',
        unitPrice: 45.9,
        total: 550.8,
        available: true,
      ),
      CartLine(
        id: 2,
        productId: 'p2',
        name: 'Pizza margherita',
        hue: 20,
        quantity: 1,
        addons: [],
        notes: '',
        unitPrice: 45,
        total: 45,
        available: false,
      ),
    ],
    itemCount: 13,
    subtotal: 550.8,
    deliveryFee: 0,
    discount: 55.08,
    total: 495.72,
    couponCode: 'RANGO10',
    couponApplied: true,
    couponPercentOff: 10,
  );

  Future<void> pumpCart(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ThemeData? theme,
  }) async {
    setSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RangoTheme.light,
        home: CartScreen(
          cart: cart,
          loading: false,
          onBack: () {},
          onOpenProduct: (_) {},
          onChangeQuantity: (_, _) {},
          onRemove: (_) {},
          onClear: () {},
          onApplyCoupon: (_) async => true,
          onCheckout: () {},
          onContinueShopping: () {},
        ),
      ),
    );
  }

  group('Detalhe do produto', () {
    testWidgets('mostra o conteúdo do protótipo', (tester) async {
      await pumpProduct(tester);

      for (final text in [
        'Casa do Burger · Hambúrguer',
        'R\$ 34,90',
        'R\$ 42,90',
        '4,8',
        'avaliação',
        '25-35',
        'minutos',
        // Produto abaixo de R$ 50 paga entrega, como no protótipo.
        'R\$ 7,90',
        'entrega',
        'Descrição',
        'Dois blends de 120g. Pão brioche, 2 blends de 120g.',
        'Ingredientes',
        'Adicionais',
        'opcional',
        'Bacon extra',
        '+ R\$ 4,00',
        'Observações',
        'Adicionar · R\$ 34,90',
        'produto · foto grande',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('adicionais e quantidade recalculam o total', (tester) async {
      await pumpProduct(tester);

      await tapVisible(tester, find.text('Bacon extra'));
      expect(find.text('Adicionar · R\$ 38,90'), findsOneWidget);

      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await tester.pump();
      expect(find.text('Adicionar · R\$ 77,80'), findsOneWidget);

      await tapVisible(tester, find.text('Bacon extra'));
      expect(find.text('Adicionar · R\$ 69,80'), findsOneWidget);
    });

    testWidgets('mostra o carregamento antes do detalhe chegar', (
      tester,
    ) async {
      await pumpProduct(tester, productDetail: null);

      expect(find.text(sample.name), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);
    });

    for (final (name, size, theme) in [
      ('tela pequena não estoura', const Size(320, 568), RangoTheme.light),
      ('tema escuro renderiza sem erro', const Size(390, 844), RangoTheme.dark),
    ]) {
      testWidgets(name, (tester) async {
        await pumpProduct(tester, size: size, theme: theme);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Carrinho', () {
    testWidgets('mostra linhas, cupom e totais', (tester) async {
      await pumpCart(tester);

      for (final text in [
        'Carrinho',
        '13 itens · R\$ 550,80',
        'Limpar',
        'R\$ 45,90 · un.',
        '+ Bacon extra · Refrigerante 350ml',
        '“sem cebola, ponto da carne bem passado”',
        'Indisponível no momento',
        'RANGO10',
        'Aplicar',
        'Subtotal',
        'Taxa de entrega',
        'Grátis',
        'Desconto · RANGO10',
        '- R\$ 55,08',
        'Total',
        'Finalizar pedido',
        'Continuar comprando',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.text('R\$ 495,72'), findsNWidgets(2));
    });

    for (final (name, size, theme) in [
      ('tela pequena não estoura', const Size(320, 568), RangoTheme.light),
      ('tema escuro renderiza sem erro', const Size(390, 844), RangoTheme.dark),
    ]) {
      testWidgets(name, (tester) async {
        await pumpCart(tester, size: size, theme: theme);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Produto e carrinho com o back-end', () {
    testWidgets('adicionar pelo detalhe manda adicionais e observação', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Burger duplo cheddar').first);
      await settle(tester);
      expect(find.byType(ProductScreen), findsOneWidget);
      expect(backend.requests.last, 'GET /products/p1');
      expect(find.text('Adicionar · R\$ 30,00'), findsOneWidget);

      await tapVisible(tester, find.text('Bacon extra'));
      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await tester.enterText(find.byType(TextField), 'sem cebola');
      await tester.pump();
      expect(find.text('Adicionar · R\$ 68,00'), findsOneWidget);

      await tester.tap(find.textContaining('Adicionar ·'));
      await settle(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Produto adicionado ao carrinho.'), findsOneWidget);
      expect(find.byTooltip('Carrinho, 2 itens'), findsOneWidget);
      final line = backend.cart.single;
      expect(
        (line.productId, line.quantity, line.addonIds.join(), line.notes),
        ('p1', 2, 'a1', 'sem cebola'),
      );
    });

    testWidgets('favoritar no detalhe fala com o servidor', (tester) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Burger duplo cheddar').first);
      await settle(tester);
      await tester.tap(find.byTooltip('Adicionar aos favoritos'));
      await settle(tester);

      expect(backend.favorites, contains('p1'));
      expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    });

    testWidgets('quantidade, entrega grátis, cupom e remoção', (tester) async {
      final backend = FakeBackend()..seedCart('p1');
      await pumpLoggedIn(tester, backend: backend);

      await tester.tap(find.byTooltip('Carrinho, 1 itens'));
      await settle(tester);
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('1 item · R\$ 30,00'), findsOneWidget);
      expect(find.text('R\$ 7,90'), findsOneWidget);
      expect(find.text('R\$ 37,90'), findsNWidgets(2));

      // R$ 60 de subtotal: a entrega fica grátis.
      await tester.tap(find.byTooltip('Aumentar quantidade'));
      await settle(tester);
      expect(find.text('2 itens · R\$ 60,00'), findsOneWidget);
      expect(find.text('Grátis'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'errado');
      await tester.tap(find.text('Aplicar'));
      await settle(tester);
      expect(find.text('Cupom inválido.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'rango10');
      expect(find.text('RANGO10'), findsOneWidget);
      await tester.tap(find.text('Aplicar'));
      await settle(tester);
      expect(find.text('Cupom RANGO10 aplicado · 10% off.'), findsOneWidget);
      expect(find.text('Desconto · RANGO10'), findsOneWidget);
      expect(find.text('R\$ 54,00'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remover Burger duplo cheddar'));
      await settle(tester);
      expect(find.text('Produto removido.'), findsOneWidget);
      expect(find.text('Seu carrinho está vazio'), findsOneWidget);
      expect(backend.cart, isEmpty);

      await tester.tap(find.text('Explorar produtos'));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('diminuir abaixo de 1 remove a linha', (tester) async {
      final backend = FakeBackend()..seedCart('p1');
      await pumpLoggedIn(tester, backend: backend);

      await tester.tap(find.byTooltip('Carrinho, 1 itens'));
      await settle(tester);
      await tester.tap(find.byTooltip('Diminuir quantidade'));
      await settle(tester);

      expect(backend.requests.last, 'DELETE /cart/items/1');
      expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    });

    testWidgets('limpar esvazia o carrinho', (tester) async {
      final backend = FakeBackend()
        ..seedCart('p1')
        ..seedCart('p2', quantity: 2);
      await pumpLoggedIn(tester, backend: backend);

      await tester.tap(find.byTooltip('Carrinho, 3 itens'));
      await settle(tester);
      expect(find.text('Pizza margherita'), findsOneWidget);

      await tester.tap(find.text('Limpar'));
      await settle(tester);
      expect(find.text('Carrinho esvaziado.'), findsOneWidget);
      expect(find.text('nenhum item'), findsOneWidget);
      expect(backend.cart, isEmpty);
    });

    testWidgets('imagem da linha abre o detalhe e voltar retorna ao carrinho', (
      tester,
    ) async {
      final backend = FakeBackend()..seedCart('p2');
      await pumpLoggedIn(tester, backend: backend);

      await tester.tap(find.byTooltip('Carrinho, 1 itens'));
      await settle(tester);
      await tester.tap(find.byType(ProductImage));
      await settle(tester);
      expect(find.byType(ProductScreen), findsOneWidget);
      expect(find.text('Pizza margherita'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });
}
