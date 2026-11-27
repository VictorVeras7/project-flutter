import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../../data/search.dart';
import '../checkout/checkout_components.dart';
import '../theme/rango_theme.dart';

// Folha "Filtros". Trabalha num rascunho: só "Aplicar filtros" devolve os
// filtros novos; fechar descarta.
Future<SearchFilters?> showFilterSheet(
  BuildContext context, {
  required SearchFilters filters,
  required List<String> categories,
}) => showModalBottomSheet<SearchFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  barrierColor: const Color(0x73000000),
  // No protótipo a folha ocupa no máximo 90% da tela.
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
  ),
  builder: (context) => _FilterSheet(initial: filters, categories: categories),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.categories});

  final SearchFilters initial;
  final List<String> categories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late var _draft = widget.initial;

  void _set(SearchFilters draft) => setState(() => _draft = draft);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtros',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              _CloseButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  _Group(
                    title: 'Categoria',
                    child: _Chips(
                      options: [for (final c in widget.categories) (c, c)],
                      selected: _draft.category,
                      onSelect: (c) => _set(_draft.copyWith(category: c)),
                    ),
                  ),
                  _Group(
                    title: 'Faixa de preço',
                    trailing: Text(
                      'até ${formatMoney(_draft.maxPrice)}',
                      style: const TextStyle(
                        color: RangoColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: _PriceSlider(
                      value: _draft.maxPrice,
                      onChanged: (v) => _set(_draft.copyWith(maxPrice: v)),
                    ),
                  ),
                  _Group(
                    title: 'Avaliação mínima',
                    child: _Chips(
                      options: ratingOptions,
                      selected: _draft.minRating,
                      onSelect: (r) => _set(_draft.copyWith(minRating: r)),
                    ),
                  ),
                  _Group(
                    title: 'Tempo de entrega',
                    child: _Chips(
                      options: deliveryTimeOptions,
                      selected: _draft.maxTime,
                      onSelect: (t) => _set(_draft.copyWith(maxTime: t)),
                    ),
                  ),
                  _Group(
                    title: 'Ordenar por',
                    spacing: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final sort in SearchSort.values)
                          _SortRow(
                            label: sort.label,
                            selected: _draft.sort == sort,
                            onTap: () => _set(_draft.copyWith(sort: sort)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                flex: 5,
                child: OutlinedButton(
                  onPressed: () => _set(SearchFilters.none),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const FittedBox(child: Text('Limpar filtros')),
                ),
              ),
              Expanded(
                flex: 7,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const FittedBox(child: Text('Aplicar filtros')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.outline),
    );

    return Semantics(
      button: true,
      label: 'Fechar filtros',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 34,
            child: Icon(Icons.close_rounded, size: 19, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.child,
    this.trailing,
    this.spacing = 9,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        child,
      ],
    );
  }
}

// Chips de escolha única de um grupo.
class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final soft = RangoPalette.of(context).soft;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final (value, label) in options)
          Builder(
            builder: (context) {
              final on = value == selected;
              final shape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: on ? colors.primary : colors.outline),
              );
              return Semantics(
                selected: on,
                inMutuallyExclusiveGroup: true,
                child: Material(
                  color: on ? soft : colors.surfaceContainerHighest,
                  shape: shape,
                  child: InkWell(
                    customBorder: shape,
                    onTap: () => onSelect(value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: on ? colors.primary : colors.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Slider de R$ 10 a R$ 80, de 5 em 5, com trilho fino e alça redonda
// (o input range do protótipo, não o visual padrão do Material 3).
class _PriceSlider extends StatelessWidget {
  const _PriceSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.outline,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.12),
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            showValueIndicator: ShowValueIndicator.never,
            // A alça fica dentro da largura, como no input range do protótipo.
            padding: const EdgeInsets.symmetric(horizontal: 9),
          ),
          child: SizedBox(
            height: 32,
            child: Slider(
              value: value,
              min: minPriceFilter,
              max: maxPriceFilter,
              divisions: (maxPriceFilter - minPriceFilter) ~/ priceFilterStep,
              semanticFormatterCallback: (v) => 'até ${formatMoney(v)}',
              onChanged: onChanged,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatMoney(minPriceFilter).replaceAll(',00', ''),
              style: labelStyle,
            ),
            Text(
              formatMoney(maxPriceFilter).replaceAll(',00', ''),
              style: labelStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? RangoPalette.of(context).soft : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              spacing: 11,
              children: [
                RadioMark(selected: selected),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
