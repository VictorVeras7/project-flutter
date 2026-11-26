import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:rango/app.dart';
import 'package:rango/data/order.dart';
import 'package:rango/ui/cart/cart_screen.dart';
import 'package:rango/ui/components/bottom_nav_bar.dart';
import 'package:rango/ui/home/home_screen.dart';
import 'package:rango/ui/order/order_detail_screen.dart';
import 'package:rango/ui/order/order_placed_screen.dart';
import 'package:rango/ui/order/orders_screen.dart';
import 'package:rango/ui/order/tracking_screen.dart';
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

  final created = DateTime.utc(2026, 9, 12, 19, 14);

  OrderSummary summary(OrderStatus status, String label) => OrderSummary(
    code: 'RG-10482',
    status: status,
    statusLabel: label,
    createdAt: created,
    total: 71.8,
    itemCount: 3,
    itemsSummary: '1× Burger duplo cheddar, 2× Limonada suíça',
    hue: 48,
  );

  OrderDetail detail({
    OrderStatus status = OrderStatus.live,
    String label = 'Em preparação',
    int step = 2,
  }) => OrderDetail(
    summary: summary(status, label),
    step: step,
    hint: 'Seu pedido está sendo preparado',
    timeline: [
      for (var i = 0; i < 5; i++)
        TimelineStep(
          step: i,
          label: const [
            'Pedido recebido',
            'Pedido confirmado',
            'Em preparação',
            'Saiu para entrega',
            'Entregue',
          ][i],
          // Como no servidor: a etapa atual só é "current" em andamento.
          state: i < step || (i == step && status != OrderStatus.live)
              ? TimelineState.done
              : i == step
              ? TimelineState.current
              : TimelineState.upcoming,
          reachedAt: i <= step ? created.add(Duration(minutes: i)) : null,
        ),
    ],
    minMinutes: 25,
    maxMinutes: 35,
    items: const [
      OrderItem(
        name: 'Burger duplo cheddar',
        restaurant: 'Casa do Burger',
        hue: 48,
        quantity: 1,
        total: 38.9,
      ),
      OrderItem(
        name: 'Limonada suíça',
        restaurant: 'Casa do Burger',
        hue: 100,
        quantity: 2,
        total: 19.8,
      ),
    ],
    addressLine: 'Rua das Palmeiras, 128 · apto 42',
    paymentType: 'pix',
    paymentLabel: 'PIX',
    subtotal: 58.7,
    deliveryFee: 7.9,
    discount: 5.87,
    courierName: 'Rafael Souza',
    courierVehicle: 'Honda CG 160',
  );

  TrackingScreen tracking(OrderDetail? order) =>
      TrackingScreen(order: order, onBack: () {}, onChat: () {}, onCall: () {});

  OrdersScreen ordersScreen(
    Map<OrderGroup, List<OrderSummary>> orders, {
    OrderGroup group = OrderGroup.live,
    ValueChanged<OrderGroup>? onSelectGroup,
  }) => OrdersScreen(
    orders: orders,
    group: group,
    onSelectGroup: onSelectGroup ?? (_) {},
    onLoad: (_) async {},
    onOpen: (_) {},
    onTrack: (_) {},
    onReorder: (_) {},
    onOrderNow: () {},
  );

  OrderDetailScreen detailScreen(OrderDetail? order) =>
      OrderDetailScreen(order: order, onBack: () {}, onReorder: () {});

  group('Datas', () {
    test('hoje mostra "Hoje"; outro dia mostra dia e mês', () {
      final now = DateTime(2026, 11, 25, 20);
      expect(
        formatOrderDate(DateTime(2026, 11, 25, 19, 42), now: now),
        'Hoje · 19:42',
      );
      expect(
        formatOrderDate(DateTime(2026, 8, 12, 20, 15), now: now),
        '12 ago · 20:15',
      );
    });
  });

  group('Acompanhar pedido', () {
    testWidgets('mostra status, timeline e entregador', (tester) async {
      await pumpScreen(tester, tracking(detail()));

      for (final text in [
        'Acompanhar pedido',
        'RG-10482',
        'mapa · rota em tempo real',
        'Seu pedido está sendo preparado',
        '25-35 min',
        'Pedido recebido',
        'Saiu para entrega',
        'agora',
        'Rafael Souza',
        'Entregador · Honda CG 160',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // A etapa atual aparece no cartão e na timeline.
      expect(find.text('Em preparação'), findsNWidgets(2));
      expect(find.text('previsto'), findsNWidgets(2));
      expect(find.text(formatTime(created)), findsOneWidget);
      expect(find.byTooltip('Ligar para o entregador'), findsOneWidget);
    });

    testWidgets('entregue troca a previsão por "Entregue"', (tester) async {
      await pumpScreen(
        tester,
        tracking(detail(status: OrderStatus.done, label: 'Entregue', step: 4)),
      );

      expect(find.text('Entregue'), findsNWidgets(3));
      expect(find.text('agora'), findsNothing);
    });

    testWidgets('mostra o carregamento antes do pedido', (tester) async {
      await pumpScreen(tester, tracking(null));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Meus pedidos', () {
    testWidgets('em andamento tem "Acompanhar"', (tester) async {
      await pumpScreen(
        tester,
        ordersScreen({
          OrderGroup.live: [summary(OrderStatus.live, 'Em preparação')],
        }),
      );

      for (final text in [
        'Meus pedidos',
        'Em andamento',
        'Anteriores',
        'RG-10482',
        'Em preparação',
        '1× Burger duplo cheddar, 2× Limonada suíça',
        '3 itens · R\$ 71,80',
        'Acompanhar',
        'Pedir novamente',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.textContaining('12 set · '), findsOneWidget);
    });

    testWidgets('anteriores não têm "Acompanhar" e o vazio muda de título', (
      tester,
    ) async {
      final orders = {
        OrderGroup.live: const <OrderSummary>[],
        OrderGroup.past: [summary(OrderStatus.cancel, 'Cancelado')],
      };
      OrderGroup? selected;
      await pumpScreen(
        tester,
        ordersScreen(orders, onSelectGroup: (g) => selected = g),
      );
      expect(find.text('Nenhum pedido em andamento'), findsOneWidget);
      expect(find.text('Fazer um pedido'), findsOneWidget);

      await tester.tap(find.text('Anteriores'));
      expect(selected, OrderGroup.past);

      await pumpScreen(tester, ordersScreen(orders, group: OrderGroup.past));
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Acompanhar'), findsNothing);
      expect(find.text('Pedir novamente'), findsOneWidget);
    });
  });

  group('Detalhes do pedido', () {
    testWidgets('mostra produtos, informações e valores', (tester) async {
      await pumpScreen(
        tester,
        detailScreen(
          detail(status: OrderStatus.done, label: 'Entregue', step: 4),
        ),
      );

      for (final text in [
        'Detalhes do pedido',
        'RG-10482',
        'Produtos',
        '1× Burger duplo cheddar',
        '2× Limonada suíça',
        'ENDEREÇO DE ENTREGA',
        'Rua das Palmeiras, 128 · apto 42',
        'PAGAMENTO',
        'PIX',
        'REALIZADO EM',
        'STATUS FINAL',
        'Subtotal',
        'R\$ 7,90',
        'Desconto',
        '- R\$ 5,87',
        'Total pago',
        'R\$ 71,80',
        'Pedir novamente',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Etiqueta do cabeçalho e "Status final".
      expect(find.text('Entregue'), findsNWidgets(2));
    });
  });

  group('Barra inferior', () {
    testWidgets('mostra as cinco abas e os badges', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          bottomNavigationBar: BottomNavBar(
            current: NavTab.orders,
            onSelect: (_) {},
            badges: const {NavTab.orders: 2, NavTab.favorites: 0},
          ),
        ),
      );

      for (final label in [
        'Início',
        'Buscar',
        'Pedidos',
        'Favoritos',
        'Perfil',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      // O badge fica do tamanho do número, sem cobrir o ícone.
      final badge = find
          .ancestor(of: find.text('2'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(badge).width, lessThan(30));
      expect(find.bySemanticsLabel('Pedidos, 2'), findsOneWidget);
    });
  });

  for (final (name, size, theme) in [
    ('tela pequena não estoura', const Size(320, 568), RangoTheme.light),
    ('tema escuro renderiza sem erro', const Size(390, 844), RangoTheme.dark),
  ]) {
    testWidgets('telas de pedido: $name', (tester) async {
      for (final screen in [
        tracking(detail()),
        tracking(
          detail(status: OrderStatus.cancel, label: 'Cancelado', step: 1),
        ),
        ordersScreen({
          OrderGroup.live: [summary(OrderStatus.live, 'Saiu para entrega')],
        }),
        ordersScreen({OrderGroup.live: const []}),
        detailScreen(detail()),
      ]) {
        await pumpScreen(tester, screen, size: size, theme: theme);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
    });
  }

  group('Pedidos com o back-end', () {
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

    testWidgets('aba Pedidos lista, abre o detalhe e pede de novo', (
      tester,
    ) async {
      final backend = await pumpLoggedIn(tester);

      await tester.tap(find.text('Pedidos'));
      await settle(tester);
      expect(find.byType(OrdersScreen), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
      expect(find.text('Nenhum pedido em andamento'), findsOneWidget);

      await tester.tap(find.text('Anteriores'));
      await settle(tester);
      expect(find.text('RG-10391'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
      expect(backend.requests, contains('GET /orders'));

      await tester.tap(find.text('1× Pizza margherita'));
      await settle(tester);
      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.text('1× Pizza margherita'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsNothing);

      await tester.tap(find.text('Pedir novamente'));
      await settle(tester);
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Itens adicionados ao carrinho.'), findsOneWidget);
      expect(backend.cart.single.productId, 'p2');

      // Voltar: carrinho → detalhe → pedidos → início.
      for (final screen in [OrderDetailScreen, OrdersScreen, HomeScreen]) {
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(find.byType(screen), findsOneWidget, reason: '$screen');
        // De volta à lista, a aba "Anteriores" continua aberta.
        if (screen == OrdersScreen) {
          expect(find.text('RG-10391'), findsOneWidget);
        }
      }
    });

    testWidgets('acompanhamento atualiza a cada 5 s até a entrega', (
      tester,
    ) async {
      final backend = FakeBackend()..seedLiveOrder(step: 1);
      await pumpLoggedIn(tester, backend: backend);
      // Badge de pedidos em andamento na barra.
      expect(find.bySemanticsLabel('Pedidos, 1'), findsOneWidget);

      await tester.tap(find.text('Pedidos'));
      await settle(tester);
      await tester.tap(find.text('Acompanhar'));
      await settle(tester);
      expect(find.byType(TrackingScreen), findsOneWidget);
      // Cada leitura avança uma etapa no back-end falso.
      expect(find.text('Seu pedido está sendo preparado'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('O entregador está levando seu pedido'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Bom apetite!'), findsOneWidget);

      // Entregue: para de buscar.
      final reads = backend.requests.where((r) => r.startsWith('GET /orders/'));
      final count = reads.length;
      await tester.pump(const Duration(seconds: 15));
      await settle(tester);
      expect(
        backend.requests.where((r) => r.startsWith('GET /orders/')).length,
        count,
      );

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('sair do acompanhamento para a atualização', (tester) async {
      final backend = FakeBackend()
        ..advanceOnRead = false
        ..seedLiveOrder(step: 2);
      await pumpLoggedIn(tester, backend: backend);
      await tester.tap(find.text('Pedidos'));
      await settle(tester);
      await tester.tap(find.text('Acompanhar'));
      await settle(tester);

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      final count = backend.requests.length;
      await tester.pump(const Duration(seconds: 20));
      await settle(tester);
      expect(backend.requests.length, count);
    });

    testWidgets('pedido realizado abre o acompanhamento', (tester) async {
      final backend = FakeBackend()
        ..advanceOnRead = false
        ..seedCart('p1');
      await pumpLoggedIn(tester, backend: backend);
      await tester.tap(find.byTooltip('Carrinho, 1 itens'));
      await settle(tester);
      await tester.tap(find.text('Finalizar pedido'));
      await settle(tester);
      await tester.tap(find.text('Confirmar pedido'));
      await settle(tester);
      expect(find.byType(OrderPlacedScreen), findsOneWidget);

      await tester.tap(find.text('Acompanhar pedido'));
      await settle(tester);
      expect(find.byType(TrackingScreen), findsOneWidget);
      expect(find.text('RG-10482'), findsOneWidget);
      expect(find.text('Pedido confirmado'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(find.byType(OrderPlacedScreen), findsOneWidget);
    });

    testWidgets('abas ainda não feitas avisam "em breve"', (tester) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.text('Buscar'));
      await settle(tester);
      expect(find.text('Buscar estará disponível em breve.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
