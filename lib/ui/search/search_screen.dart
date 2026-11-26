import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../../data/search.dart';
import '../checkout/checkout_components.dart';
import '../components/empty_state.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'filter_sheet.dart';

// Busca: campo com espera ao digitar, filtros, recentes, sugestões e
// resultados vindos do servidor.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.query,
    required this.filters,
    required this.idle,
    required this.results,
    required this.total,
    required this.recent,
    required this.suggestions,
    required this.categories,
    required this.favoriteIds,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onPickTerm,
    required this.onClearRecent,
    required this.onApplyFilters,
    required this.onChangeFilters,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  final String query;
  final SearchFilters filters;
  // Sem termo e sem filtros: recentes e sugestões no lugar dos resultados.
  final bool idle;
  // null = carregando.
  final List<Product>? results;
  final int total;
  final List<String> recent;
  final List<SearchSuggestion> suggestions;
  final List<String> categories;
  final Set<String> favoriteIds;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  // Busca recente ou sugestão tocada.
  final ValueChanged<String> onPickTerm;
  final VoidCallback onClearRecent;
  // "Aplicar filtros" da folha.
  final ValueChanged<SearchFilters> onApplyFilters;
  // Chip removido ou "Limpar filtros" do estado vazio.
  final ValueChanged<SearchFilters> onChangeFilters;
  final ValueChanged<String> onOpenProduct;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onAddToCart;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.query);
  final _focus = FocusNode();

  // O termo pode mudar por fora ("Ver tudo" da Home zera a busca).
  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Tira o foco do próprio campo: assim a tela esquece o campo e não o
  // devolve com o teclado quando a folha de filtros fecha.
  void _hideKeyboard() => _focus.unfocus();

  void _pick(String term) {
    _controller.text = term;
    _hideKeyboard();
    widget.onPickTerm(term);
  }

  void _clear() {
    _controller.clear();
    widget.onQueryChanged('');
  }

  Future<void> _openFilters() async {
    _hideKeyboard();
    final applied = await showFilterSheet(
      context,
      filters: widget.filters,
      categories: widget.categories,
    );
    if (applied != null) widget.onApplyFilters(applied);
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            controller: _controller,
            focusNode: _focus,
            filters: widget.filters,
            onChanged: widget.onQueryChanged,
            onSubmit: widget.onSubmit,
            onClear: _clear,
            onOpenFilters: _openFilters,
            onChangeFilters: widget.onChangeFilters,
          ),
          Expanded(
            child: !widget.idle && results == null
                ? const CheckoutLoading()
                : ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                    children: [
                      if (widget.idle)
                        _Idle(
                          recent: widget.recent,
                          suggestions: widget.suggestions,
                          onPick: _pick,
                          onClearRecent: widget.onClearRecent,
                        )
                      else if (results!.isEmpty)
                        EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nenhum produto encontrado.',
                          text: 'Tente outro termo ou ajuste os filtros aplicados.',
                          verticalPadding: 40,
                          action: EmptyStateButton(
                            label: 'Limpar filtros',
                            outlined: true,
                            onPressed: () =>
                                widget.onChangeFilters(SearchFilters.none),
                          ),
                        )
                      else ...[
                        _ResultsTitle(
                          count: widget.total,
                          sort: widget.filters.sort,
                        ),
                        for (final product in results) ...[
                          const SizedBox(height: 13),
                          ProductRow(
                            product: product,
                            subtitle:
                                '${product.restaurant} · ${product.category}',
                            favorite: widget.favoriteIds.contains(product.id),
                            onOpen: () => widget.onOpenProduct(product.id),
                            onToggleFavorite: () =>
                                widget.onToggleFavorite(product.id),
                            onAdd: () => widget.onAddToCart(product.id),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
