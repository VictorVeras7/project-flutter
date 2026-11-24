import 'package:flutter/foundation.dart';

import 'data/product.dart';
import 'data/remote/api_models.dart';
import 'data/remote/mappers.dart';
import 'data/remote/rango_api.dart';

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
  StoreMessage? message;

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
    // Atualiza na hora e desfaz se o servidor recusar.
    _setFavorite(id, favorite);
    _show(
      favorite ? 'Adicionado aos favoritos.' : 'Removido dos favoritos.',
      favorite ? MessageKind.success : MessageKind.info,
    );
    _api.setFavorite(id, favorite).catchError((Object e) {
      _setFavorite(id, !favorite);
      _show(_errorText(e), MessageKind.error);
    });
  }

  Future<void> addToCart(String productId) => _safely(() async {
    cartCount = (await _api.addToCart(productId, 1)).itemCount;
    _show('Produto adicionado ao carrinho.', MessageKind.success);
  });

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
