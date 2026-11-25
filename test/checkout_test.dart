import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/cart.dart';
import 'package:rango/data/checkout.dart';
import 'package:rango/data/order.dart';
import 'package:rango/ui/checkout/address_screen.dart';
import 'package:rango/ui/checkout/checkout_screen.dart';
import 'package:rango/ui/checkout/payment_screen.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/order/order_placed_screen.dart';
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
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

  const home = Address(
    id: 1,
    label: 'Casa',
    street: 'Rua das Palmeiras, 128',
    line: 'Rua das Palmeiras, 128 · apto 42',
    cityLine: 'Pinheiros · São Paulo',
    selected: true,
  );
  const work = Address(
    id: 2,
    label: 'Trabalho',
    street: 'Av. Faria Lima, 3400',
    line: 'Av. Faria Lima, 3400 · 9º andar',
    cityLine: 'Itaim Bibi · São Paulo',
    selected: false,
  );
  const pix = PaymentMethod(
    id: 1,
    type: PaymentType.pix,
    label: 'PIX',
    detail: 'Aprovação imediata',
  );
  const credit = PaymentMethod(
    id: 2,
    type: PaymentType.credit,
    label: 'Cartão de crédito',
    detail: 'Visa •••• 4410',
  );
  const cart = Cart(
    lines: [
      CartLine(
        id: 1,
        productId: 'p1',
        name: 'Burger duplo cheddar com bacon e molho especial',
        hue: 48,
        quantity: 2,
        addons: ['Bacon extra', 'Refrigerante 350ml'],
        notes: '',
        unitPrice: 45.9,
        total: 91.8,
        available: true,
      ),
    ],
    itemCount: 2,
    subtotal: 91.8,
    deliveryFee: 0,
    discount: 9.18,
    total: 82.62,
    couponCode: 'RANGO10',
    couponApplied: true,
    couponPercentOff: 10,
  );
  const order = PlacedOrder(
    code: 'RG-10482',
    minMinutes: 25,
    maxMinutes: 35,
    paymentLabel: 'Cartão de crédito',
    itemCount: 3,
    total: 71.8,
  );

  CheckoutScreen checkout({bool placing = false}) => CheckoutScreen(
    cart: cart,
    address: home,
    payment: pix,
    loading: false,
    placing: placing,
    onBack: () {},
    onChangeAddress: () {},
    onChangePayment: () {},
    onConfirm: () {},
  );

  AddressScreen addressScreen({SaveAddress? onSave}) => AddressScreen(
    addresses: const [home, work],
    selectedId: 1,
    loading: false,
    onBack: () {},
    onChoose: (_) {},
    onSave: onSave ?? (_) async => const {},
    onConfirm: () async => true,
  );

  PaymentScreen paymentScreen(int selectedId) => PaymentScreen(
    methods: const [pix, credit],
    selectedId: selectedId,
    loading: false,
    onBack: () {},
    onChoose: (_) {},
  );

  OrderPlacedScreen placedScreen() =>
      OrderPlacedScreen(order: order, onTrack: () {}, onHome: () {});

  group('Checkout', () {
    testWidgets('mostra endereço, pagamento e resumo', (tester) async {
      await pumpScreen(tester, checkout());

      for (final text in [
        'Finalizar pedido',
        'Endereço de entrega',
        'Casa',
        'Rua das Palmeiras, 128 · apto 42',
        'Pinheiros · São Paulo',
        'Forma de pagamento',
        'PIX',
        'Aprovação imediata',
        'Resumo do pedido',
        '2× Burger duplo cheddar com bacon e molho especial',
        '+ Bacon extra · Refrigerante 350ml',
        'Subtotal',
        'Grátis',
        'Desconto · RANGO10',
        '- R\$ 9,18',
        'Total',
        'R\$ 82,62',
        'Confirmar pedido',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Alterar'), findsNWidgets(2));
    });

    testWidgets('enviando mostra o processamento', (tester) async {
      await pumpScreen(tester, checkout(placing: true));

      expect(find.text('Processando pagamento...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Endereço', () {
    testWidgets('lista os endereços com o selecionado marcado', (tester) async {
      await pumpScreen(tester, addressScreen());

      for (final text in [
        'Endereço de entrega',
        'mapa · localização',
        'Casa',
        'Trabalho',
        'Av. Faria Lima, 3400 · 9º andar',
        'Cadastrar novo endereço',
        'Usar este endereço',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Novo endereço'), findsNothing);
    });

    testWidgets('formulário valida antes de enviar', (tester) async {
      AddressForm? sent;
      await pumpScreen(
        tester,
        addressScreen(
          onSave: (form) async {
            sent = form;
            return const {};
          },
        ),
      );

      await tapVisible(tester, find.text('Cadastrar novo endereço'));
      expect(find.text('Novo endereço'), findsOneWidget);

      await tapVisible(tester, find.text('Salvar endereço'));
      expect(find.text('CEP inválido.'), findsOneWidget);
      expect(find.text('Informe rua e número.'), findsOneWidget);
      expect(sent, isNull);

      Finder field(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );
      await tester.enterText(field('CEP'), '01310-100');
      await tester.enterText(field('Rua e número'), 'Av. Paulista, 1000');
      await tester.enterText(field('Bairro'), 'Bela Vista');
      await tester.enterText(field('Cidade'), 'São Paulo');
      await tapVisible(tester, find.text('Salvar endereço'));

      expect(sent?.street, 'Av. Paulista, 1000');
      expect(sent?.complement, '');
      expect(find.text('Novo endereço'), findsNothing);
    });
  });

  group('Pagamento', () {
    testWidgets('dados do cartão só aparecem para cartão', (tester) async {
      await pumpScreen(tester, paymentScreen(1));
      expect(find.text('Visa •••• 4410'), findsOneWidget);
      expect(find.text('Dados do cartão'), findsNothing);

      await pumpScreen(tester, paymentScreen(2));
      expect(find.text('Dados do cartão'), findsOneWidget);
      expect(find.text('dados enviados por conexão segura'), findsOneWidget);
      expect(find.text('Confirmar forma de pagamento'), findsOneWidget);
    });
  });

  group('Pedido realizado', () {
    testWidgets('mostra o resumo do protótipo', (tester) async {
      await pumpScreen(tester, placedScreen());
      await tester.pump(const Duration(milliseconds: 600));

      for (final text in [
        'Pedido realizado\ncom sucesso!',
        'Você receberá notificações sobre cada etapa do preparo e da entrega.',
        'Número do pedido',
        'RG-10482',
        'Previsão de entrega',
        '25-35 min',
        'Pagamento',
        'Cartão de crédito',
        '3 itens',
        'R\$ 71,80',
        'Acompanhar pedido',
        'Voltar ao início',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });
  });

  for (final (name, size, theme) in [
    ('tela pequena não estoura', const Size(320, 568), RangoTheme.light),
    ('tema escuro renderiza sem erro', const Size(390, 844), RangoTheme.dark),
  ]) {
    testWidgets('telas do checkout: $name', (tester) async {
      for (final screen in [
        checkout(),
        checkout(placing: true),
        addressScreen(),
        paymentScreen(2),
        placedScreen(),
      ]) {
        await pumpScreen(tester, screen, size: size, theme: theme);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
    });
  }

  group('Checkout com o back-end', () {
    Future<FakeBackend> openCheckout(WidgetTester tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession('refresh-1');
      final backend = FakeBackend()..seedCart('p1', quantity: 2);
      await tester.pumpWidget(RangoApp(api: backend.api()));
      await settle(tester);
      await tester.tap(find.byTooltip('Carrinho, 2 itens'));
      await settle(tester);
      await tester.tap(find.text('Finalizar pedido'));
      await settle(tester);
      return backend;
    }

    testWidgets('pedido usa o endereço e o pagamento escolhidos', (
      tester,
    ) async {
      final backend = await openCheckout(tester);
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Rua das Palmeiras, 128 · apto 42'), findsOneWidget);
      expect(find.text('PIX'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Alterar Forma de pagamento'));
      await settle(tester);
      await tester.tap(find.text('Cartão de crédito'));
      await settle(tester);
      expect(find.text('Dados do cartão'), findsOneWidget);
      await tester.tap(find.text('Confirmar forma de pagamento'));
      await settle(tester);
      expect(find.text('Visa •••• 4410'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Alterar Endereço de entrega'));
      await settle(tester);
      await tester.tap(find.text('Trabalho'));
      await settle(tester);
      await tester.tap(find.text('Usar este endereço'));
      await settle(tester);
      expect(find.text('Endereço atualizado.'), findsOneWidget);
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Av. Faria Lima, 3400 · 9º andar'), findsOneWidget);

      await tester.tap(find.text('Confirmar pedido'));
      await settle(tester);
      expect(find.byType(OrderPlacedScreen), findsOneWidget);
      expect(find.text('RG-10482'), findsOneWidget);
      expect(find.text('Cartão de crédito'), findsOneWidget);
      expect(find.text('2 itens'), findsOneWidget);
      expect(backend.orders.single, {'addressId': 2, 'paymentMethodId': 2});
      expect(backend.cart, isEmpty);

      await tester.tap(find.text('Voltar ao início'));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byTooltip('Carrinho'), findsOneWidget);
      // A Home reflete o endereço escolhido no checkout.
      expect(find.text('Av. Faria Lima, 3400'), findsOneWidget);
    });

    testWidgets('voltar do sistema no pedido realizado vai para a Home', (
      tester,
    ) async {
      await openCheckout(tester);
      await tester.tap(find.text('Confirmar pedido'));
      await settle(tester);
      expect(find.byType(OrderPlacedScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('endereço novo entra na lista já escolhido', (tester) async {
      final backend = await openCheckout(tester);

      await tester.tap(find.bySemanticsLabel('Alterar Endereço de entrega'));
      await settle(tester);
      await tapVisible(tester, find.text('Cadastrar novo endereço'));

      Finder field(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );
      await tester.enterText(field('CEP'), '01310100');
      await tester.enterText(field('Rua e número'), 'Av. Paulista, 1000');
      await tester.enterText(field('Complemento'), 'sala 5');
      await tester.enterText(field('Bairro'), 'Bela Vista');
      await tester.enterText(field('Cidade'), 'São Paulo');
      await tapVisible(tester, find.text('Salvar endereço'));

      expect(find.text('Endereço salvo.'), findsOneWidget);
      expect(find.text('Av. Paulista, 1000 · sala 5'), findsOneWidget);
      expect(backend.addresses.last['label'], 'Outro');

      await tester.tap(find.text('Usar este endereço'));
      await settle(tester);
      expect(find.text('Av. Paulista, 1000 · sala 5'), findsOneWidget);
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('endereço da Home abre a escolha de endereço', (tester) async {
      setSize(tester, const Size(390, 844));
      setSavedSession('refresh-1');
      await tester.pumpWidget(RangoApp(api: FakeBackend().api()));
      await settle(tester);

      await tester.tap(find.text('Rua das Palmeiras, 128'));
      await settle(tester);
      expect(find.byType(AddressScreen), findsOneWidget);

      await tester.tap(find.text('Trabalho'));
      await settle(tester);
      await tester.tap(find.text('Usar este endereço'));
      await settle(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Av. Faria Lima, 3400'), findsOneWidget);
    });
  });
}
