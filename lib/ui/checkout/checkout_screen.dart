import 'package:material_ui/material_ui.dart';

import '../../data/cart.dart';
import '../../data/checkout.dart';
import '../../data/product.dart';
import '../components/auth_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'checkout_components.dart';

// Finalizar pedido: endereço, pagamento e resumo do carrinho do servidor.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.address,
    required this.payment,
    required this.loading,
    required this.placing,
    required this.onBack,
    required this.onChangeAddress,
    required this.onChangePayment,
    required this.onConfirm,
  });

  final Cart cart;
  final Address? address;
  final PaymentMethod? payment;
  final bool loading;
  // Pedido sendo enviado: o botão mostra "Processando pagamento...".
  final bool placing;
  final VoidCallback onBack;
  final VoidCallback onChangeAddress;
  final VoidCallback onChangePayment;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutHeader(title: 'Finalizar pedido', onBack: onBack),
          Expanded(
            child: loading
                ? const CheckoutLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    children: [
                      _AddressCard(address: address, onChange: onChangeAddress),
                      const SizedBox(height: 14),
                      _PaymentCard(payment: payment, onChange: onChangePayment),
                      const SizedBox(height: 14),
                      _OrderSummary(cart: cart),
                    ],
                  ),
          ),
          CheckoutBottomBar(
            child: Opacity(
              opacity: placing ? 0.85 : 1,
              child: AuthSubmitButton(
                label: placing
                    ? 'Processando pagamento...'
                    : 'Confirmar pedido',
                loading: placing,
                onPressed: loading || placing || cart.isEmpty
                    ? () {}
                    : onConfirm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.onChange,
  });

  final Widget icon;
  final String title;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        icon,
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onChange,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text('Alterar', semanticsLabel: 'Alterar $title'),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onChange});

  final Address? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final address = this.address;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 11,
        children: [
          _CardTitle(
            icon: const Icon(
              Icons.location_on_rounded,
              size: 19,
              color: RangoColors.primary,
            ),
            title: 'Endereço de entrega',
            onChange: onChange,
          ),
          if (address == null)
            Text(
              'Cadastre um endereço para receber o pedido.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  address.label,
                  style: const TextStyle(
                    color: RangoColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  address.line,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  address.cityLine,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.onChange});

  final PaymentMethod? payment;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final payment = this.payment;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 11,
        children: [
          _CardTitle(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 19,
              color: RangoColors.primary,
            ),
            title: 'Forma de pagamento',
            onChange: onChange,
          ),
          if (payment == null)
            Text(
              'Escolha uma forma de pagamento.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Row(
              spacing: 11,
              children: [
                SoftIcon(icon: paymentIcon(payment.type)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.label,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        payment.detail,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final free = cart.deliveryFee == 0;
    final rows = [
      ('Subtotal', formatMoney(cart.subtotal), false),
      (
        'Taxa de entrega',
        free ? 'Grátis' : formatMoney(cart.deliveryFee),
        free,
      ),
      if (cart.discount > 0)
        (
          'Desconto · ${cart.couponCode}',
          '- ${formatMoney(cart.discount)}',
          true,
        ),
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Resumo do pedido',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final line in cart.lines) _SummaryLine(line: line),
          Divider(height: 1, thickness: 1, color: colors.outline),
          for (final (label, value, highlight) in rows)
            Row(
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
            ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      spacing: 11,
      children: [
        SizedBox.square(
          dimension: 36,
          child: ProductImage(
            hue: line.hue,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${line.quantity}× ${line.name}',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (line.addons.isNotEmpty)
                Text(
                  '+ ${line.addons.join(' · ')}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatMoney(line.total),
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
