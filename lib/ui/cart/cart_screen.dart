import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cart.dart';
import '../../data/product.dart';
import '../components/auth_components.dart';
import '../components/product_card.dart';
import '../components/quantity_stepper.dart';
import '../theme/rango_theme.dart';

// Carrinho: as linhas, o cupom e os totais vêm prontos do servidor.
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.loading,
    required this.onBack,
    required this.onOpenProduct,
    required this.onChangeQuantity,
    required this.onRemove,
    required this.onClear,
    required this.onApplyCoupon,
    required this.onCheckout,
    required this.onContinueShopping,
  });

  final Cart cart;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenProduct;
  final void Function(CartLine line, int delta) onChangeQuantity;
  final ValueChanged<CartLine> onRemove;
  final VoidCallback onClear;
  final Future<bool> Function(String code) onApplyCoupon;
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final _coupon = TextEditingController(text: _appliedCode);

  String get _appliedCode =>
      widget.cart.couponApplied ? widget.cart.couponCode ?? '' : '';

  @override
  void didUpdateWidget(CartScreen old) {
    super.didUpdateWidget(old);
    // Cupom salvo no servidor chega depois da primeira carga.
    if (_coupon.text.isEmpty && _appliedCode.isNotEmpty) {
      _coupon.text = _appliedCode;
    }
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    widget.onApplyCoupon(_coupon.text);
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            cart: cart,
            onBack: widget.onBack,
            onClear: cart.isEmpty ? null : widget.onClear,
          ),
          if (widget.loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: RangoColors.primary),
              ),
            )
          else if (cart.isEmpty)
            Expanded(child: _Empty(onExplore: widget.onContinueShopping))
          else ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  for (final line in cart.lines) ...[
                    _LineCard(
                      line: line,
                      onOpen: () => widget.onOpenProduct(line.productId),
                      onMinus: () => widget.onChangeQuantity(line, -1),
                      onPlus: line.quantity < 99
                          ? () => widget.onChangeQuantity(line, 1)
                          : null,
                      onRemove: () => widget.onRemove(line),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _CouponRow(
                    controller: _coupon,
                    applied: cart.couponApplied,
                    onApply: _apply,
                  ),
                  const SizedBox(height: 14),
                  _Summary(cart: cart),
                ],
              ),
            ),
            _BottomBar(
              total: cart.total,
              onCheckout: widget.onCheckout,
              onContinueShopping: widget.onContinueShopping,
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cart,
    required this.onBack,
    required this.onClear,
  });

  final Cart cart;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = cart.itemCount;
    final summary = count == 0
        ? 'nenhum item'
        : '$count ${count == 1 ? 'item' : 'itens'} · '
              '${formatMoney(cart.subtotal)}';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 13),
          child: Row(
            spacing: 12,
            children: [
              AuthBackButton(onPressed: onBack),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carrinho',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      summary,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Limpar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              foregroundPainter: _DashedBorder(color: colors.outline),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(44),
                ),
                child: Icon(
                  Icons.remove_shopping_cart_outlined,
                  size: 58,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Seu carrinho está vazio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                'Explore os restaurantes e adicione seus pratos favoritos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 21),
            FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Explorar produtos'),
            ),
          ],
        ),
      ),
    );
  }
}

// Borda tracejada do ícone do carrinho vazio (border: 1px dashed).
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(44),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.onOpen,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onOpen;
  final VoidCallback onMinus;
  final VoidCallback? onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const small = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: RangoPalette.of(context).shadow,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Opacity(
              opacity: line.available ? 1 : 0.5,
              child: SizedBox.square(
                dimension: 80,
                child: ProductImage(
                  hue: line.hue,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        line.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Remover ${line.name}',
                      child: InkResponse(
                        onTap: onRemove,
                        radius: 18,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatMoney(line.unitPrice)} · un.',
                  style: small.copyWith(color: colors.onSurfaceVariant),
                ),
                if (line.addons.isNotEmpty)
                  Text(
                    '+ ${line.addons.join(' · ')}',
                    style: small.copyWith(color: RangoColors.primary),
                  ),
                if (line.notes.isNotEmpty)
                  Text(
                    '“${line.notes}”',
                    style: small.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (!line.available)
                  Text(
                    'Indisponível no momento',
                    style: small.copyWith(color: colors.error),
                  ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    QuantityStepper(
                      compact: true,
                      quantity: line.quantity,
                      onMinus: onMinus,
                      onPlus: onPlus,
                    ),
                    // Totais grandes em tela estreita encolhem em vez de estourar.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatMoney(line.total),
                          style: const TextStyle(
                            color: RangoColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow({
    required this.controller,
    required this.applied,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const style = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700);

    return Row(
      spacing: 9,
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: applied ? RangoColors.success : colors.outline,
                width: 1.5,
              ),
            ),
            child: Row(
              spacing: 9,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
                Expanded(
                  child: Semantics(
                    label: 'Cupom promocional',
                    child: TextField(
                      controller: controller,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30),
                        _UpperCase(),
                      ],
                      onSubmitted: (_) => onApply(),
                      style: style.copyWith(color: colors.onSurface),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Cupom promocional',
                        hintStyle: style.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                if (applied)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 19,
                    color: RangoColors.success,
                  ),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onApply,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// O protótipo mostra o cupom em maiúsculas (text-transform: uppercase).
class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final free = cart.deliveryFee == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        spacing: 11,
        children: [
          _SummaryRow(label: 'Subtotal', value: formatMoney(cart.subtotal)),
          _SummaryRow(
            label: 'Taxa de entrega',
            value: free ? 'Grátis' : formatMoney(cart.deliveryFee),
            highlight: free,
          ),
          if (cart.discount > 0)
            _SummaryRow(
              label: 'Desconto · ${cart.couponCode}',
              value: '- ${formatMoney(cart.discount)}',
              highlight: true,
            ),
          Divider(height: 1, thickness: 1, color: colors.outline),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatMoney(cart.total),
                style: const TextStyle(
                  color: RangoColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  // Entrega grátis e desconto aparecem em verde.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? RangoColors.success : colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.total,
    required this.onCheckout,
    required this.onContinueShopping,
  });

  final double total;
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          FilledButton(
            onPressed: onCheckout,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Finalizar pedido')),
                Text(formatMoney(total)),
              ],
            ),
          ),
          TextButton(
            onPressed: onContinueShopping,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: colors.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Continuar comprando'),
          ),
        ],
      ),
    );
  }
}
