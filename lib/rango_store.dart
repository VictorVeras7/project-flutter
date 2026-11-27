import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/cart.dart';
import 'data/checkout.dart';
import 'data/order.dart';
import 'data/product.dart';
import 'data/remote/api_models.dart';
import 'data/remote/mappers.dart';
import 'data/remote/rango_api.dart';
import 'data/search.dart';

enum MessageKind { success, error, info }

// Aviso para a parte de baixo da tela; o App limpa depois de mostrar.
typedef StoreMessage = ({String text, MessageKind kind});

// Estado do app vindo do back-end e as ações que conversam com ele.
// As telas recebem modelos simples; aqui ficam as chamadas e o tratamento de erro.
class RangoStore extends ChangeNotifier {
  RangoStore(this._api);

  final RangoApi _api;

  var userName = '';
  String? address;
  var cartCount = 0;
  var unreadNotifications = 0;
  var categories = const [allCategories];
  // Seções da Home na ordem do protótipo.
  var sections = <ProductTag, List<Product>>{};
  // Produtos de cada categoria, buscados ao tocar no chip.
  final categoryProducts = <String, List<Product>>{};
  var favoriteIds = <String>{};
  var homeLoading = false;
  // Detalhe do produto aberto. `productPreview` vem das listas da Home e
  // desenha o topo da tela enquanto o detalhe carrega.
  Product? productPreview;
  ProductDetail? productDetail;
  var cart = Cart.empty;
  // Primeira carga do carrinho nesta sessão: mostra o carregamento.
  var cartLoading = false;
  // Checkout: endereço e pagamento escolhidos ficam aqui até confirmar o pedido.
  var addresses = <Address>[];
  var paymentMethods = <PaymentMethod>[];
  int? selectedAddressId;
  int? selectedPaymentId;
  var checkoutLoading = false;
  var placingOrder = false;
  PlacedOrder? lastOrder;
  // Badges da barra inferior.
  var liveOrderCount = 0;
  var favoriteCount = 0;
  // "Meus pedidos", por aba. Ausente = ainda não carregou.
  final orders = <OrderGroup, List<OrderSummary>>{};
  // Aba aberta em "Meus pedidos"; fica ao voltar do detalhe, como no protótipo.
  var ordersGroup = OrderGroup.live;
  // Pedido acompanhado (atualizado a cada 5 s) e pedido aberto no detalhe.
  OrderDetail? trackedOrder;
  OrderDetail? openedOrder;
  // Busca: termo, filtros e resultados continuam ao voltar do produto.
  var searchQuery = '';
  var searchFilters = SearchFilters.none;
  // Resultados da busca; null = carregando.
  List<Product>? searchResults;
  var searchTotal = 0;
  var recentSearches = <String>[];
  var suggestions = <SearchSuggestion>[];
  // Favoritos, mais recentes primeiro; null = ainda não carregou.
  List<Product>? favorites;
  StoreMessage? message;

  // Espera depois da última tecla antes de buscar.
  static const searchDelay = Duration(milliseconds: 300);
  Timer? _searchTimer;
  // Só a busca mais recente vale; as anteriores são descartadas na volta.
  var _searchRequest = 0;

  static const trackingInterval = Duration(seconds: 5);
  Timer? _trackingTimer;
  String? _trackingCode;
  String? _openedCode;

  String? _openProductId;

  var _categorySlugs = <String, String>{};

  // Sessão

  Future<Map<String, String>> login(
    String email,
    String password,
    bool keepSignedIn,
  ) => _authenticate(() => _api.login(email, password, keepSignedIn));

  Future<Map<String, String>> register(RegisterRequest request) =>
      _authenticate(() => _api.register(request));

  // Devolve os erros por campo; erros sem campo viram aviso e uma chave vazia.
  Future<Map<String, String>> _authenticate(
    Future<String> Function() block,
  ) async {
    try {
      userName = await block();
      return const {};
    } on ApiException catch (e) {
      if (e.code == 'INVALID_CREDENTIALS') return {'password': e.message};
      if (e.code == 'EMAIL_IN_USE') return {'email': e.message};
      if (e.fields.isNotEmpty) return e.fields;
      _show(e.message, MessageKind.error);
      return {'': e.message};
    }
  }

  Future<bool> restoreSession() => _api.restoreSession();

  void onSessionExpired(VoidCallback action) {
    _api.onSessionExpired = () {
      // O aviso vem do erro da própria chamada que encerrou a sessão.
      _clear();
      action();
    };
  }

  void _clear() {
    userName = '';
    address = null;
    cartCount = 0;
    unreadNotifications = 0;
    categories = const [allCategories];
    sections = {};
    categoryProducts.clear();
    favoriteIds = {};
    _categorySlugs = {};
    productPreview = null;
    productDetail = null;
    _openProductId = null;
    cart = Cart.empty;
    cartLoading = false;
    addresses = [];
    paymentMethods = [];
    selectedAddressId = null;
    selectedPaymentId = null;
    checkoutLoading = false;
    placingOrder = false;
    lastOrder = null;
    liveOrderCount = 0;
    favoriteCount = 0;
    orders.clear();
    ordersGroup = OrderGroup.live;
    stopTracking();
    closeOrder();
    _searchTimer?.cancel();
    _searchRequest++;
    searchQuery = '';
    searchFilters = SearchFilters.none;
    searchResults = null;
    searchTotal = 0;
    recentSearches = [];
    suggestions = [];
    favorites = null;
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  // Home

  Future<void> loadHome() async {
    homeLoading = true;
    notifyListeners();
    try {
      final home = await _api.home();
      userName = home.userName;
      address = home.address;
      cartCount = home.cartItemCount;
      unreadNotifications = home.unreadNotifications;
      _categorySlugs = {for (final c in home.categories) c.name: c.slug};
      categories = [allCategories, ..._categorySlugs.keys];
      sections = {
        for (final section in home.sections)
          ?ProductTag.fromApi(section.key): _products(section.products),
      };
    } on ApiException catch (e) {
      _show(e.message, MessageKind.error);
    } on Object {
      _show('Algo deu errado. Tente novamente.', MessageKind.error);
    }
    homeLoading = false;
    notifyListeners();
  }

  // Chips da Home: busca os produtos da categoria ("Todos" já vem da Home).
  Future<void> loadCategory(String name) async {
    final slug = _categorySlugs[name];
    if (slug == null) return;
    await _safely(() async {
      categoryProducts[name] = _products(await _api.products(slug));
    });
  }

  void toggleFavorite(String id) {
    final favorite = !favoriteIds.contains(id);
    final previousList = favorites;
    // Atualiza na hora e desfaz se o servidor recusar.
    if (previousList != null) {
      final others = previousList.where((p) => p.id != id);
      final product = favorite ? _findProduct(id) : null;
      // O novo favorito entra no topo, como na ordem do servidor.
      favorites = [?product, ...others];
    }
    _setFavorite(id, favorite);
    favoriteCount += favorite ? 1 : -1;
    _show(
      favorite ? 'Adicionado aos favoritos.' : 'Removido dos favoritos.',
      favorite ? MessageKind.success : MessageKind.info,
    );
    _api.setFavorite(id, favorite).catchError((Object e) {
      // A lista volta como estava, com o item no mesmo lugar.
      favorites = previousList;
      _setFavorite(id, !favorite);
      favoriteCount += favorite ? -1 : 1;
      _show(_errorText(e), MessageKind.error);
    });
  }

  // Favoritos

  // Lista da aba e o número da barra; a ordem é a do servidor.
  Future<void> loadFavorites() => _safely(() async {
    _setFavorites(await _api.favorites());
  });

  void _setFavorites(FavoriteListDto list) {
    final products = [for (final dto in list.data) dto.toProduct()];
    favorites = products;
    favoriteCount = list.count;
    favoriteIds = {for (final p in products) p.id};
  }

  // Busca

  // Sem termo e sem filtros: mostra recentes e sugestões.
  bool get searchIdle => searchQuery.trim().isEmpty && searchFilters.isEmpty;

  // Aba "Buscar" mantém a busca anterior; "Ver tudo" da Home troca pelos
  // filtros da seção.
  Future<void> openSearch({SearchFilters? filters}) async {
    if (filters != null) {
      _searchTimer?.cancel();
      searchQuery = '';
      searchFilters = filters;
      searchResults = null;
    }
    notifyListeners();
    if (!searchIdle && (filters != null || searchResults == null)) {
      unawaited(_runSearch());
    }
    await _safely(() async {
      final (recent, names) = await (
        _api.recentSearches(),
        _api.searchSuggestions(),
      ).wait;
      recentSearches = recent;
      // O protótipo mostra quatro, com o resumo do produto embaixo.
      suggestions = [for (final name in names.take(4)) _suggestion(name)];
    });
  }

  SearchSuggestion _suggestion(String name) {
    final product = _allProducts().where((p) => p.name == name).firstOrNull;
    if (product == null) return SearchSuggestion(name);
    return SearchSuggestion(
      name,
      '${product.restaurant} · ${formatRating(product.rating)} · '
      '${formatMoney(product.price)}',
    );
  }

  // Ao digitar: espera 300 ms sem novas teclas antes de buscar.
  void setSearchQuery(String query) {
    if (query == searchQuery) return;
    searchQuery = query;
    _searchTimer?.cancel();
    if (searchIdle) {
      _searchRequest++;
      searchResults = null;
    } else {
      _searchTimer = Timer(searchDelay, _runSearch);
    }
    notifyListeners();
  }

  // Busca recente ou sugestão tocada: busca na hora.
  void searchFor(String term) {
    searchQuery = term;
    unawaited(_runSearch());
  }

  // "Buscar" do teclado: busca na hora e guarda o termo.
  void submitSearch() {
    if (searchQuery.trim().isEmpty) return;
    unawaited(_runSearch());
    unawaited(saveRecentSearch());
  }

  // Folha de filtros (com aviso), chips e "Limpar filtros".
  void applySearchFilters(SearchFilters filters, {bool announce = false}) {
    searchFilters = filters;
    if (announce) _show('Filtros aplicados.', MessageKind.success);
    unawaited(_runSearch());
  }

  Future<void> _runSearch() async {
    _searchTimer?.cancel();
    final request = ++_searchRequest;
    if (searchIdle) {
      searchResults = null;
      notifyListeners();
      return;
    }
    final filters = searchFilters;
    // Os resultados anteriores ficam na tela até os novos chegarem.
    notifyListeners();
    try {
      final list = await _api.searchProducts(
        searchQuery.trim(),
        filters,
        categorySlug: filters.hasCategory
            ? _categorySlugs[filters.category]
            : null,
      );
      if (request != _searchRequest) return;
      searchResults = _products(list.data);
      searchTotal = list.total;
    } on Object catch (e) {
      if (request != _searchRequest) return;
      searchResults ??= const [];
      _show(_errorText(e), MessageKind.error);
    }
    notifyListeners();
  }

  // Ao confirmar a busca ou abrir um produto dos resultados. Falha aqui
  // não atrapalha a busca, então não mostra aviso.
  Future<void> saveRecentSearch() async {
    final term = searchQuery.trim();
    if (term.isEmpty) return;
    try {
      recentSearches = await _api.saveRecentSearch(term);
      notifyListeners();
    } on Object {
      // Sessão encerrada já é tratada pela API.
    }
  }

  // "Limpar" das buscas recentes; volta a lista se o servidor recusar.
  Future<void> clearRecentSearches() async {
    final previous = recentSearches;
    recentSearches = [];
    notifyListeners();
    try {
      await _api.clearRecentSearches();
    } on Object catch (e) {
      recentSearches = previous;
      _show(_errorText(e), MessageKind.error);
    }
  }

  // Produto

  // Busca ingredientes e adicionais. Devolve false se não deu para abrir.
  Future<bool> openProduct(String id) async {
    _openProductId = id;
    productPreview = _findProduct(id);
    productDetail = null;
    notifyListeners();
    try {
      final dto = await _api.product(id);
      // O usuário já saiu ou abriu outro produto.
      if (_openProductId != id) return true;
      productDetail = dto.toDetail();
      _setFavorite(id, dto.summary.isFavorite);
      return true;
    } on Object catch (e) {
      if (_openProductId != id) return true;
      _show(_errorText(e), MessageKind.error);
      return false;
    }
  }

  void closeProduct() {
    _openProductId = null;
    productPreview = null;
    productDetail = null;
  }

  Product? _findProduct(String id) =>
      _allProducts().where((p) => p.id == id).firstOrNull;

  // Todos os produtos que o app já recebeu (Home, categorias, busca e favoritos).
  Iterable<Product> _allProducts() => [
    ...sections.values,
    ...categoryProducts.values,
    ?searchResults,
    ?favorites,
  ].expand((list) => list);

  // Carrinho

  Future<void> loadCart() async {
    // Mostra o carregamento só na primeira vez; depois atualiza por baixo.
    cartLoading = cart.isEmpty && cartCount > 0;
    notifyListeners();
    await _safely(() async => _setCart(await _api.cart()));
    cartLoading = false;
    notifyListeners();
  }

  // Devolve true se o produto entrou no carrinho.
  Future<bool> addToCart(
    String productId, {
    int quantity = 1,
    List<String> addonIds = const [],
    String notes = '',
  }) async {
    var added = false;
    await _safely(() async {
      _setCart(
        await _api.addToCart(
          productId,
          quantity: quantity,
          addonIds: addonIds,
          notes: notes.trim(),
        ),
      );
      added = true;
      _show('Produto adicionado ao carrinho.', MessageKind.success);
    });
    return added;
  }

  // + e − da linha; abaixo de 1 remove, como no protótipo.
  Future<void> changeQuantity(CartLine line, int delta) {
    final quantity = line.quantity + delta;
    return _safely(() async {
      _setCart(
        quantity < 1
            ? await _api.removeCartItem(line.id)
            : await _api.setCartQuantity(line.id, quantity),
      );
    });
  }

  Future<void> removeLine(CartLine line) => _safely(() async {
    _setCart(await _api.removeCartItem(line.id));
    _show('Produto removido.', MessageKind.info);
  });

  Future<void> clearCart() => _safely(() async {
    _setCart(await _api.clearCart());
    _show('Carrinho esvaziado.', MessageKind.info);
  });

  // Devolve true se o cupom foi aplicado.
  Future<bool> applyCoupon(String code) async {
    if (code.trim().isEmpty) {
      _show('Informe o cupom.', MessageKind.error);
      return false;
    }
    var applied = false;
    await _safely(() async {
      _setCart(await _api.applyCoupon(code.trim()));
      applied = true;
      _show(
        'Cupom ${cart.couponCode} aplicado · ${cart.couponPercentOff}% off.',
        MessageKind.success,
      );
    });
    return applied;
  }

  // Checkout

  Address? get selectedAddress =>
      addresses.where((a) => a.id == selectedAddressId).firstOrNull;

  PaymentMethod? get selectedPayment =>
      paymentMethods.where((p) => p.id == selectedPaymentId).firstOrNull;

  // Endereços, formas de pagamento e o carrinho atualizado, em paralelo.
  Future<void> loadCheckout() async {
    checkoutLoading = addresses.isEmpty || paymentMethods.isEmpty;
    notifyListeners();
    await _safely(() async {
      final (addressList, payments, cartDto) = await (
        _api.addresses(),
        _api.paymentMethods(),
        _api.cart(),
      ).wait;
      _setAddresses(addressList);
      paymentMethods = [for (final p in payments) p.toPaymentMethod()];
      // Mantém a escolha anterior; senão, a primeira (PIX, como no protótipo).
      if (selectedPayment == null && paymentMethods.isNotEmpty) {
        selectedPaymentId = paymentMethods.first.id;
      }
      _setCart(cartDto);
    });
    checkoutLoading = false;
    notifyListeners();
  }

  // Só as listas da tela de endereços (aberta também pela Home).
  Future<void> loadAddresses() async {
    checkoutLoading = addresses.isEmpty;
    notifyListeners();
    await _safely(() async => _setAddresses(await _api.addresses()));
    checkoutLoading = false;
    notifyListeners();
  }

  void _setAddresses(List<AddressDto> list) {
    addresses = [for (final a in list) a.toAddress()];
    // A escolha local vale até confirmar; sem escolha, usa a do servidor.
    if (selectedAddress == null) {
      selectedAddressId = addresses
          .where((a) => a.selected)
          .followedBy(addresses)
          .firstOrNull
          ?.id;
    }
  }

  void chooseAddress(int id) {
    selectedAddressId = id;
    notifyListeners();
  }

  void choosePayment(int id) {
    selectedPaymentId = id;
    notifyListeners();
  }

  // "Usar este endereço": salva a escolha no servidor e atualiza a Home.
  Future<bool> confirmAddress() async {
    final id = selectedAddressId;
    if (id == null) {
      _show('Cadastre um endereço de entrega.', MessageKind.error);
      return false;
    }
    var saved = false;
    await _safely(() async {
      final dto = await _api.selectAddress(id);
      address = dto.street;
      addresses = [
        for (final a in addresses)
          Address(
            id: a.id,
            label: a.label,
            street: a.street,
            line: a.line,
            cityLine: a.cityLine,
            selected: a.id == id,
          ),
      ];
      saved = true;
      _show('Endereço atualizado.', MessageKind.success);
    });
    return saved;
  }

  // Devolve os erros por campo; vazio quando salvou.
  Future<Map<String, String>> createAddress(AddressForm form) async {
    try {
      final dto = await _api.createAddress(
        // O protótipo não pede nome para o endereço novo.
        label: 'Outro',
        cep: form.cep,
        street: form.street,
        complement: form.complement,
        neighborhood: form.neighborhood,
        city: form.city,
      );
      final created = dto.toAddress();
      addresses = [...addresses, created];
      selectedAddressId = created.id;
      _show('Endereço salvo.', MessageKind.success);
      return const {};
    } on ApiException catch (e) {
      if (e.fields.isNotEmpty) return e.fields;
      _show(e.message, MessageKind.error);
      return {'': e.message};
    } on Object {
      _show('Algo deu errado. Tente novamente.', MessageKind.error);
      return const {'': 'Algo deu errado. Tente novamente.'};
    }
  }

  // Confirma o pedido. Devolve true se o pedido foi criado.
  Future<bool> placeOrder() async {
    final addressId = selectedAddressId;
    final paymentId = selectedPaymentId;
    if (addressId == null) {
      _show('Cadastre ou selecione um endereço de entrega.', MessageKind.error);
      return false;
    }
    if (paymentId == null) {
      _show('Escolha uma forma de pagamento.', MessageKind.error);
      return false;
    }
    placingOrder = true;
    notifyListeners();
    var placed = false;
    await _safely(() async {
      final order = await _api.placeOrder(
        addressId: addressId,
        paymentMethodId: paymentId,
      );
      lastOrder = order.toPlacedOrder();
      // O servidor esvaziou o carrinho; o pedido novo entra em andamento.
      cart = Cart.empty;
      cartCount = 0;
      liveOrderCount++;
      orders.remove(OrderGroup.live);
      placed = true;
    });
    placingOrder = false;
    notifyListeners();
    return placed;
  }

  // Barra inferior

  // Pedidos em andamento e favoritos. Falha aqui não merece aviso:
  // os badges só somem até a próxima carga.
  Future<void> loadNavBadges() async {
    try {
      final (live, favorites) = await (
        _api.orders(OrderGroup.live.apiKey, pageSize: 1),
        _api.favorites(),
      ).wait;
      liveOrderCount = live.total;
      _setFavorites(favorites);
      notifyListeners();
    } on Object {
      // Sessão encerrada já é tratada pela API; o resto é ignorado.
    }
  }

  // Meus pedidos

  void selectOrdersGroup(OrderGroup group) {
    if (group == ordersGroup) return;
    ordersGroup = group;
    notifyListeners();
    loadOrders(group);
  }

  Future<void> loadOrders(OrderGroup group) => _safely(() async {
    final list = await _api.orders(group.apiKey);
    orders[group] = [for (final o in list.data) o.toSummary()];
    if (group == OrderGroup.live) {
      liveOrderCount = list.total;
    } else {
      // Um pedido pode ter sido entregue desde a última conta do badge.
      unawaited(loadNavBadges());
    }
  });

  // Acompanhamento: busca agora e a cada 5 s, até o pedido terminar.
  Future<void> startTracking(String code) async {
    stopTracking();
    _trackingCode = code;
    if (trackedOrder?.code != code) trackedOrder = null;
    notifyListeners();
    final ok = await _refreshTracked(showErrors: true);
    if (!ok || _trackingCode != code) return;
    _trackingTimer = Timer.periodic(
      trackingInterval,
      (_) => _refreshTracked(showErrors: false),
    );
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _trackingCode = null;
  }

  Future<bool> _refreshTracked({required bool showErrors}) async {
    final code = _trackingCode;
    if (code == null) return false;
    try {
      final detail = (await _api.order(code)).toDetail();
      if (_trackingCode != code) return false;
      final wasLive = trackedOrder?.isLive ?? true;
      trackedOrder = detail;
      if (!detail.isLive) {
        _trackingTimer?.cancel();
        // Terminou durante o acompanhamento: as listas mudaram.
        if (wasLive) {
          orders.clear();
          unawaited(loadNavBadges());
        }
      }
      notifyListeners();
      return detail.isLive;
    } on Object catch (e) {
      // Na repetição, falha de rede some na próxima tentativa.
      if (showErrors) _show(_errorText(e), MessageKind.error);
      return false;
    }
  }

  // Detalhes do pedido.
  Future<bool> openOrder(String code) async {
    _openedCode = code;
    if (openedOrder?.code != code) openedOrder = null;
    notifyListeners();
    try {
      final detail = (await _api.order(code)).toDetail();
      if (_openedCode == code) openedOrder = detail;
      notifyListeners();
      return true;
    } on Object catch (e) {
      if (_openedCode != code) return true;
      _show(_errorText(e), MessageKind.error);
      return false;
    }
  }

  void closeOrder() {
    _openedCode = null;
    openedOrder = null;
  }

  // "Pedir novamente". Devolve true se algo entrou no carrinho.
  Future<bool> reorder(String code) async {
    var added = false;
    await _safely(() async {
      final result = await _api.reorder(code);
      _setCart(result.cart);
      added = !cart.isEmpty;
      if (!added) {
        _show(
          'Os itens deste pedido não estão mais disponíveis.',
          MessageKind.error,
        );
      } else if (result.skippedProductIds.isNotEmpty) {
        _show(
          'Itens adicionados ao carrinho. Alguns não estão mais disponíveis.',
          MessageKind.info,
        );
      } else {
        _show('Itens adicionados ao carrinho.', MessageKind.success);
      }
    });
    return added;
  }

  void _setCart(CartDto dto) {
    cart = dto.toCart();
    cartCount = cart.itemCount;
  }

  void clearMessage() => message = null;

  // Infra

  List<Product> _products(List<ProductDto> list) {
    for (final dto in list) {
      if (dto.isFavorite) {
        favoriteIds.add(dto.id);
      } else {
        favoriteIds.remove(dto.id);
      }
    }
    return [for (final dto in list) dto.toProduct()];
  }

  void _setFavorite(String id, bool favorite) {
    favoriteIds = favorite
        ? {...favoriteIds, id}
        : ({...favoriteIds}..remove(id));
    notifyListeners();
  }

  void _show(String text, MessageKind kind) {
    message = (text: text, kind: kind);
    notifyListeners();
  }

  String _errorText(Object error) => error is ApiException
      ? error.message
      : 'Algo deu errado. Tente novamente.';

  Future<void> _safely(Future<void> Function() block) async {
    try {
      await block();
    } on Object catch (e) {
      _show(_errorText(e), MessageKind.error);
    }
    notifyListeners();
  }
}
