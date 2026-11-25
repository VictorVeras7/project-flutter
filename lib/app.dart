import 'package:material_ui/material_ui.dart';

import 'data/remote/rango_api.dart';
import 'rango_store.dart';
import 'ui/cart/cart_screen.dart';
import 'ui/components/auth_components.dart';
import 'ui/home/home_screen.dart';
import 'ui/login/login_screen.dart';
import 'ui/product/product_screen.dart';
import 'ui/signup/signup_screen.dart';
import 'ui/theme/rango_theme.dart';
import 'ui/welcome/welcome_screen.dart';

enum Screen { splash, welcome, login, signup, home, product, cart }

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
    if (_stack.last == Screen.product) _store.closeProduct();
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
    _store.loadHome();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => switch (_stack.last) {
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
            onOpenSearch: () => _comingSoon('Busca'),
            onOpenProfile: () => _comingSoon('Perfil'),
            onOpenAddress: () => _comingSoon('Endereços'),
            onSeeAll: (_) => _comingSoon('Busca'),
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
            onCheckout: () => _comingSoon('Checkout'),
            onContinueShopping: () => _reset([Screen.home]),
          ),
        },
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
