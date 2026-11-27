import 'package:material_ui/material_ui.dart';

import 'data/product.dart';
import 'data/remote/rango_api.dart';
import 'data/search.dart';
import 'rango_store.dart';
import 'ui/cart/cart_screen.dart';
import 'ui/checkout/address_screen.dart';
import 'ui/checkout/checkout_screen.dart';
import 'ui/checkout/payment_screen.dart';
import 'ui/components/bottom_nav_bar.dart';
import 'ui/order/order_detail_screen.dart';
import 'ui/order/order_placed_screen.dart';
import 'ui/order/orders_screen.dart';
import 'ui/order/tracking_screen.dart';
import 'ui/components/auth_components.dart';
import 'ui/favorites/favorites_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/login/login_screen.dart';
import 'ui/product/product_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/signup/signup_screen.dart';
import 'ui/theme/rango_theme.dart';
import 'ui/welcome/welcome_screen.dart';

enum Screen {
  splash,
  welcome,
  login,
  signup,
  home,
  product,
  cart,
  checkout,
  address,
  payment,
  orderPlaced,
  tracking,
  orders,
  orderDetail,
  search,
  favorites,
}

// Telas com a barra inferior, e a aba de cada uma.
const _tabScreens = {
  Screen.home: NavTab.home,
  Screen.search: NavTab.search,
  Screen.orders: NavTab.orders,
  Screen.favorites: NavTab.favorites,
};

class RangoApp extends StatelessWidget {
  const RangoApp({super.key, this.api});

  // Os testes passam uma API com cliente falso; o app usa o back-end local.
  final RangoApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rango',
      debugShowCheckedModeBanner: false,
      theme: RangoTheme.light,
      darkTheme: RangoTheme.dark,
      home: _AppHome(api: api),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome({this.api});

  final RangoApi? api;

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  late final _store = RangoStore(widget.api ?? RangoApi());
  // Pilha do protótipo: voltar retorna para a tela anterior.
  final _stack = [Screen.splash];
  // Cada abertura do detalhe recomeça quantidade, adicionais e observações.
  var _productVisit = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_showMessage);
    _store.onSessionExpired(() => _reset([Screen.welcome, Screen.login]));
    _start();
  }

  @override
  void dispose() {
    _store
      ..removeListener(_showMessage)
      ..dispose();
    super.dispose();
  }

  // Abertura: com sessão salva vai direto para a Home; senão, boas-vindas.
  Future<void> _start() async {
    final restored = await _store.restoreSession();
    if (!mounted) return;
    if (restored) {
      _enterHome();
    } else {
      _reset([Screen.welcome]);
    }
  }

  // Erros e confirmações da API aparecem no aviso da parte de baixo da tela.
  void _showMessage() {
    final message = _store.message;
    if (message == null || !mounted) return;
    _store.clearMessage();
    showRangoToast(
      context,
      message.text,
      kind: switch (message.kind) {
        MessageKind.success => RangoToastKind.success,
        MessageKind.error => RangoToastKind.error,
        MessageKind.info => RangoToastKind.info,
      },
    );
  }

  void _comingSoon(String feature) => showRangoToast(
    context,
    '$feature estará disponível em breve.',
    kind: RangoToastKind.info,
  );

  void _open(Screen screen) => setState(() => _stack.add(screen));

  void _back() {
    switch (_stack.last) {
      case Screen.product:
        _store.closeProduct();
      // Saiu do acompanhamento: para de buscar o pedido a cada 5 s.
      case Screen.tracking:
        _store.stopTracking();
      case Screen.orderDetail:
        _store.closeOrder();
      default:
    }
    setState(_stack.removeLast);
  }

  void _reset(List<Screen> stack) {
    if (!mounted) return;
    setState(() {
      _stack
        ..clear()
        ..addAll(stack);
    });
  }

  void _enterHome() {
    _reset([Screen.home]);
    _store
      ..loadHome()
      ..loadNavBadges();
  }

  // Barra inferior. As abas ficam sobre a Home: voltar retorna ao Início.
  void _selectTab(NavTab tab) {
    final current = _tabScreens[_stack.last];
    if (tab == current) return;
    switch (tab) {
      case NavTab.home:
        _reset([Screen.home]);
      case NavTab.search:
        _reset([Screen.home, Screen.search]);
        _store.openSearch();
      case NavTab.orders:
        _reset([Screen.home, Screen.orders]);
      case NavTab.favorites:
        // A tela recarrega a lista ao abrir.
        _reset([Screen.home, Screen.favorites]);
      case NavTab.profile:
        _comingSoon(tab.label);
    }
  }

  // "Ver tudo" de uma seção da Home: busca com os filtros da seção.
  void _seeAll(ProductTag tag) {
    _reset([Screen.home, Screen.search]);
    _store.openSearch(filters: SearchFilters.forSection(tag));
  }

  // Produto aberto pelos resultados: o termo entra nas buscas recentes.
  void _openSearchResult(String id) {
    _store.saveRecentSearch();
    _openProduct(id);
  }

  void _openTracking(String code) {
    _open(Screen.tracking);
    _store.startTracking(code);
  }

  Future<void> _openOrder(String code) async {
    _open(Screen.orderDetail);
    final opened = await _store.openOrder(code);
    if (!opened && mounted && _stack.last == Screen.orderDetail) _back();
  }

  // "Pedir novamente": com itens no carrinho, abre o carrinho.
  Future<void> _reorder(String code) async {
    final added = await _store.reorder(code);
    if (added && mounted) _open(Screen.cart);
  }

  // As telas das abas ganham a barra inferior; a tela não reserva o espaço
  // de baixo do sistema, que fica com a barra. Com o teclado aberto a barra
  // some, para não subir junto e tomar o espaço da busca.
  Widget _withNav(Widget screen) {
    final tab = _tabScreens[_stack.last];
    if (tab == null) return screen;
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: !typing,
            child: screen,
          ),
        ),
        if (!typing)
          BottomNavBar(
            current: tab,
            onSelect: _selectTab,
            badges: {
              NavTab.orders: _store.liveOrderCount,
              NavTab.favorites: _store.favoriteCount,
            },
          ),
      ],
    );
  }

  Future<void> _openProduct(String id) async {
    _productVisit++;
    _open(Screen.product);
    final opened = await _store.openProduct(id);
    // Não deu para carregar: o aviso já apareceu, volta para onde estava.
    if (!opened && mounted && _stack.last == Screen.product) _back();
  }

  void _openCart() {
    _open(Screen.cart);
    _store.loadCart();
  }

  void _openCheckout() {
    _open(Screen.checkout);
    _store.loadCheckout();
  }

  void _openAddress() {
    _open(Screen.address);
    _store.loadAddresses();
  }

  Future<void> _confirmOrder() async {
    final placed = await _store.placeOrder();
    // Pedido feito: a pilha recomeça na tela de sucesso, como no protótipo.
    if (placed && mounted) _reset([Screen.orderPlaced]);
  }

  // Voltar do sistema na tela de sucesso vai para a Home, não fecha o app.
  void _handleBack() {
    if (_stack.last == Screen.orderPlaced) {
      _enterHome();
    } else {
      _back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.length == 1 && _stack.last != Screen.orderPlaced,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => _withNav(switch (_stack.last) {
          Screen.splash => const _Splash(),
          Screen.welcome => WelcomeScreen(
            onLogin: () => _open(Screen.login),
            onSignup: () => _open(Screen.signup),
          ),
          Screen.login => LoginScreen(
            onBack: _back,
            authenticate: _store.login,
            onLoginSuccess: _enterHome,
            onForgotPassword: () => _comingSoon('Recuperar senha'),
            onSignup: () => _open(Screen.signup),
          ),
          Screen.signup => SignupScreen(
            onBack: _back,
            register: _store.register,
            onSignupSuccess: () {
              _enterHome();
              showRangoToast(context, 'Conta criada com sucesso!');
            },
            onLogin: () => _open(Screen.login),
          ),
          Screen.home => HomeScreen(
            userName: _store.userName,
            address: _store.address,
            cartCount: _store.cartCount,
            hasUnread: _store.unreadNotifications > 0,
            loading: _store.homeLoading,
            categories: _store.categories,
            sections: _store.sections,
            categoryProducts: _store.categoryProducts,
            favoriteIds: _store.favoriteIds,
            onCategoryChange: _store.loadCategory,
            onToggleFavorite: _store.toggleFavorite,
            onAddToCart: _store.addToCart,
            onOpenProduct: _openProduct,
            onOpenCart: _openCart,
            onOpenNotifications: () => _comingSoon('Notificações'),
            onOpenSearch: () => _selectTab(NavTab.search),
            onOpenProfile: () => _comingSoon('Perfil'),
            onOpenAddress: _openAddress,
            onSeeAll: _seeAll,
          ),
          Screen.search => SearchScreen(
            query: _store.searchQuery,
            filters: _store.searchFilters,
            idle: _store.searchIdle,
            results: _store.searchResults,
            total: _store.searchTotal,
            recent: _store.recentSearches,
            suggestions: _store.suggestions,
            categories: _store.categories,
            favoriteIds: _store.favoriteIds,
            onQueryChanged: _store.setSearchQuery,
            onSubmit: _store.submitSearch,
            onPickTerm: _store.searchFor,
            onClearRecent: _store.clearRecentSearches,
            onApplyFilters: (filters) =>
                _store.applySearchFilters(filters, announce: true),
            onChangeFilters: _store.applySearchFilters,
            onOpenProduct: _openSearchResult,
            onToggleFavorite: _store.toggleFavorite,
            onAddToCart: _store.addToCart,
          ),
          Screen.favorites => FavoritesScreen(
            favorites: _store.favorites,
            onLoad: _store.loadFavorites,
            onOpenProduct: _openProduct,
            onRemove: _store.toggleFavorite,
            onAddToCart: _store.addToCart,
            onExplore: () => _selectTab(NavTab.home),
          ),
          Screen.product => ProductScreen(
            key: ValueKey(_productVisit),
            preview: _store.productPreview,
            detail: _store.productDetail,
            favorite: _store.favoriteIds.contains(
              _store.productDetail?.product.id ?? _store.productPreview?.id,
            ),
            onBack: _back,
            onToggleFavorite: _store.toggleFavorite,
            onAdd: _store.addToCart,
          ),
          Screen.cart => CartScreen(
            cart: _store.cart,
            loading: _store.cartLoading,
            onBack: _back,
            onOpenProduct: _openProduct,
            onChangeQuantity: _store.changeQuantity,
            onRemove: _store.removeLine,
            onClear: _store.clearCart,
            onApplyCoupon: _store.applyCoupon,
            onCheckout: _openCheckout,
            onContinueShopping: () => _reset([Screen.home]),
          ),
          Screen.checkout => CheckoutScreen(
            cart: _store.cart,
            address: _store.selectedAddress,
            payment: _store.selectedPayment,
            loading: _store.checkoutLoading,
            placing: _store.placingOrder,
            onBack: _back,
            onChangeAddress: () => _open(Screen.address),
            onChangePayment: () => _open(Screen.payment),
            onConfirm: _confirmOrder,
          ),
          Screen.address => AddressScreen(
            addresses: _store.addresses,
            selectedId: _store.selectedAddressId,
            loading: _store.checkoutLoading,
            onBack: _back,
            onChoose: _store.chooseAddress,
            onSave: _store.createAddress,
            onConfirm: _store.confirmAddress,
          ),
          Screen.payment => PaymentScreen(
            methods: _store.paymentMethods,
            selectedId: _store.selectedPaymentId,
            loading: _store.checkoutLoading,
            onBack: _back,
            onChoose: _store.choosePayment,
          ),
          Screen.orderPlaced => switch (_store.lastOrder) {
            final order? => OrderPlacedScreen(
              order: order,
              onTrack: () => _openTracking(order.code),
              onHome: _enterHome,
            ),
            null => const _Splash(),
          },
          Screen.tracking => TrackingScreen(
            order: _store.trackedOrder,
            onBack: _back,
            onChat: () => _comingSoon('Conversar com o entregador'),
            onCall: () => _comingSoon('Ligar para o entregador'),
          ),
          Screen.orders => OrdersScreen(
            orders: _store.orders,
            group: _store.ordersGroup,
            onSelectGroup: _store.selectOrdersGroup,
            onLoad: _store.loadOrders,
            onOpen: _openOrder,
            onTrack: _openTracking,
            onReorder: _reorder,
            onOrderNow: () => _selectTab(NavTab.home),
          ),
          Screen.orderDetail => OrderDetailScreen(
            order: _store.openedOrder,
            onBack: _back,
            onReorder: () {
              final code = _store.openedOrder?.code;
              if (code != null) _reorder(code);
            },
          ),
        }),
      ),
    );
  }
}

// Tela de espera enquanto a sessão salva é verificada.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: RangoColors.primary),
      ),
    );
  }
}
