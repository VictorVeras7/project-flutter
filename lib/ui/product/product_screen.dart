import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../components/auth_components.dart';
import '../components/product_card.dart';
import '../components/quantity_stepper.dart';
import '../theme/rango_theme.dart';

typedef AddProduct = Future<bool> Function(
  String productId, {
  int quantity,
  List<String> addonIds,
  String notes,
});

// Detalhe do produto: adicionais, observações e quantidade ficam na tela;
// o preço total é calculado aqui e o carrinho fica no servidor.
class ProductScreen extends StatefulWidget {
  const ProductScreen({
    super.key,
    required this.preview,
    required this.detail,
    required this.favorite,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  // Resumo vindo da Home; desenha o topo enquanto o detalhe carrega.
  final Product? preview;
  final ProductDetail? detail;
  final bool favorite;
  final VoidCallback onBack;
  final ValueChanged<String> onToggleFavorite;
  final AddProduct onAdd;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _notes = TextEditingController();
  var _quantity = 1;
  var _addons = <String>{};
  var _adding = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _toggleAddon(String id) => setState(() {
    _addons = _addons.contains(id)
        ? ({..._addons}..remove(id))
        : {..._addons, id};
  });

  Future<void> _add(ProductDetail detail) async {
    setState(() => _adding = true);
    final added = await widget.onAdd(
      detail.product.id,
      quantity: _quantity,
      addonIds: _addons.toList(),
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() => _adding = false);
    if (added) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = widget.detail;
    final product = detail?.product ?? widget.preview;
    return Scaffold(
      backgroundColor: colors.surface,
      // A barra de status fica separada, como no protótipo: ao rolar, o
      // conteúdo não passa por baixo dela.
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(
                    hue: product?.hue,
                    favorite: widget.favorite,
                    onBack: widget.onBack,
                    onToggleFavorite: product == null
                        ? null
                        : () => widget.onToggleFavorite(product.id),
                  ),
                  // A folha sobe 22 px sobre a foto, como no protótipo.
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: product == null
                          ? const _Loading()
                          : _Body(
                              product: product,
                              detail: detail,
                              addons: _addons,
                              notes: _notes,
                              onToggleAddon: _toggleAddon,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            quantity: _quantity,
            total: detail == null
                ? null
                : detail.unitPrice(_addons) * _quantity,
            adding: _adding,
            onMinus: _quantity > 1 ? () => setState(() => _quantity--) : null,
            onPlus: _quantity < 99 ? () => setState(() => _quantity++) : null,
            onAdd: detail == null || _adding ? null : () => _add(detail),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.hue,
    required this.favorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  final double? hue;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final hue = this.hue;
    final overlay = Stack(
      children: [
        Positioned(
          top: 12,
          left: 16,
          child: _HeroButton(
            tooltip: 'Voltar',
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 21,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ),
        if (onToggleFavorite != null)
          Positioned(
            top: 12,
            right: 16,
            child: _HeroButton(
              tooltip: favorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onTap: onToggleFavorite!,
              child: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 21,
                color: favorite ? RangoColors.error : const Color(0xFF1F1F1F),
              ),
            ),
          ),
        if (hue != null)
          Positioned(
            bottom: 34,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xC7FFFFFF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'produto · foto grande',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Courier'],
                  fontSize: 10,
                  color: Color(0x80000000),
                ),
              ),
            ),
          ),
      ],
    );

    return SizedBox(
      height: 296,
      child: hue == null
          ? ColoredBox(color: RangoPalette.of(context).skeleton, child: overlay)
          : ProductImage(hue: hue, child: overlay),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xEBFFFFFF),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              offset: Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.product,
    required this.detail,
    required this.addons,
    required this.notes,
    required this.onToggleAddon,
  });

  final Product product;
  final ProductDetail? detail;
  final Set<String> addons;
  final TextEditingController notes;
  final ValueChanged<String> onToggleAddon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = this.detail;
    final oldPrice = product.oldPrice;
    final free = hasFreeDelivery(product.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 7,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (oldPrice != null)
                      Text(
                        formatMoney(oldPrice),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      formatMoney(product.price),
                      style: const TextStyle(
                        color: RangoColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${product.restaurant} · ${product.category}',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            _Stat(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF5A623),
              value: formatRating(product.rating),
              label: 'avaliação',
            ),
            _Stat(
              icon: Icons.schedule_rounded,
              value: '${product.minMinutes}-${product.maxMinutes}',
              label: 'minutos',
            ),
            _Stat(
              icon: Icons.delivery_dining_outlined,
              value: free ? 'Grátis' : formatMoney(standardDeliveryFee),
              label: 'entrega',
            ),
          ],
        ),
        if (detail == null)
          const _Loading()
        else ...[
          _Section(
            title: 'Descrição',
            child: _Paragraph(detail.fullDescription, size: 13.5),
          ),
          _Section(
            title: 'Ingredientes',
            child: _Paragraph(detail.ingredients, size: 13),
          ),
          Divider(height: 1, thickness: 1, color: colors.outline),
          if (detail.addons.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 11,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: _SectionTitle('Adicionais')),
                    Text(
                      'opcional',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                for (final addon in detail.addons)
                  _AddonRow(
                    addon: addon,
                    selected: addons.contains(addon.id),
                    onTap: () => onToggleAddon(addon.id),
                  ),
              ],
            ),
          _Section(
            title: 'Observações',
            spacing: 9,
            child: _NotesField(controller: notes),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: RangoColors.primary),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = RangoColors.primary,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          spacing: 3,
          children: [
            Icon(icon, size: 19, color: iconColor),
            Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.spacing = 7});

  final String title;
  final Widget child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [_SectionTitle(title), child],
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: size,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.addon,
    required this.selected,
    required this.onTap,
  });

  final Addon addon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(15);

    return Semantics(
      checked: selected,
      child: Material(
        color: selected
            ? RangoPalette.of(context).soft
            : colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              spacing: 11,
              children: [
                AuthCheckbox(checked: selected),
                Expanded(
                  child: Text(
                    addon.name,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '+ ${formatMoney(addon.price)}',
                  style: const TextStyle(
                    color: RangoColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const style = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: colors.outline, width: 1.5),
    );

    return Semantics(
      label: 'Observações',
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        style: style.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Ex: sem cebola, ponto da carne bem passado...',
          hintStyle: style.copyWith(color: colors.onSurfaceVariant),
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          counterText: '',
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.quantity,
    required this.total,
    required this.adding,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  final int quantity;
  // null enquanto o detalhe carrega.
  final double? total;
  final bool adding;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = this.total;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        13,
        18,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: Row(
        spacing: 12,
        children: [
          QuantityStepper(quantity: quantity, onMinus: onMinus, onPlus: onPlus),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                // Sem brilho quando desabilitado: apareceria atrás do botão translúcido.
                boxShadow: onAdd == null
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0xE6FF6B00),
                          offset: Offset(0, 10),
                          blurRadius: 22,
                          spreadRadius: -12,
                        ),
                      ],
              ),
              child: FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.6,
                  ),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    if (adding)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                          backgroundColor: Color(0x59FFFFFF),
                        ),
                      )
                    else
                      const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    Flexible(
                      child: Text(
                        total == null
                            ? 'Adicionar'
                            : 'Adicionar · ${formatMoney(total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
