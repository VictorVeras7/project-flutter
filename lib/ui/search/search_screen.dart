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

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.focusNode,
    required this.filters,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onOpenFilters,
    required this.onChangeFilters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchFilters filters;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;
  final ValueChanged<SearchFilters> onChangeFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chips = filters.chips;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 11,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  spacing: 9,
                  children: [
                    Expanded(
                      child: _SearchField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        onSubmit: onSubmit,
                        onClear: onClear,
                      ),
                    ),
                    _FilterButton(
                      count: filters.activeCount,
                      onTap: onOpenFilters,
                    ),
                  ],
                ),
              ),
              if (chips.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    spacing: 7,
                    children: [
                      for (final (label, without) in chips)
                        _ActiveChip(
                          label: label,
                          onTap: () => onChangeFilters(without),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outline, width: 1.5),
      ),
      child: Row(
        spacing: 9,
        children: [
          Icon(Icons.search_rounded, size: 20, color: colors.onSurfaceVariant),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              textInputAction: TextInputAction.search,
              cursorColor: colors.primary,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'O que você quer comer hoje?',
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // O "x" aparece só com texto no campo.
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : Semantics(
                    container: true,
                    button: true,
                    label: 'Limpar busca',
                    child: GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );

    return Semantics(
      button: true,
      label: switch (count) {
        0 => 'Filtros',
        1 => 'Filtros, 1 ativo',
        _ => 'Filtros, $count ativos',
      },
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: colors.primary,
                shape: shape,
                child: InkWell(
                  customBorder: shape,
                  onTap: onTap,
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: colors.onSurface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: colors.surface,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: RangoColors.primary),
    );

    return Semantics(
      button: true,
      label: 'Remover filtro $label',
      excludeSemantics: true,
      child: Material(
        color: RangoPalette.of(context).soft,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: RangoColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: RangoColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Estado inicial: buscas recentes e sugestões.
class _Idle extends StatelessWidget {
  const _Idle({
    required this.recent,
    required this.suggestions,
    required this.onPick,
    required this.onClearRecent,
  });

  final List<String> recent;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<String> onPick;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleStyle = TextStyle(
      color: colors.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 11,
          children: [
            Row(
              children: [
                Expanded(child: Text('Buscas recentes', style: titleStyle)),
                if (recent.isNotEmpty)
                  GestureDetector(
                    onTap: onClearRecent,
                    child: const Text(
                      'Limpar',
                      style: TextStyle(
                        color: RangoColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (recent.isEmpty)
              Text(
                'Nenhuma busca recente.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final term in recent)
                    _RecentChip(label: term, onTap: () => onPick(term)),
                ],
              ),
          ],
        ),
        if (suggestions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 11,
            children: [
              Text('Sugestões para você', style: titleStyle),
              Column(
                spacing: 2,
                children: [
                  for (final s in suggestions)
                    _SuggestionRow(suggestion: s, onTap: () => onPick(s.label)),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.outline),
    );

    return Material(
      color: colors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final SearchSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: RangoPalette.of(context).soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                size: 19,
                color: RangoColors.primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    suggestion.label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (suggestion.hint.isNotEmpty)
                    Text(
                      suggestion.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsTitle extends StatelessWidget {
  const _ResultsTitle({required this.count, required this.sort});

  final int count;
  final SearchSort sort;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            resultCountLabel(count),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          sort.shortLabel,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
