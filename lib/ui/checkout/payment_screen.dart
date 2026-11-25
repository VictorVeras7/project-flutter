import 'package:material_ui/material_ui.dart';

import '../../data/checkout.dart';
import '../components/auth_components.dart';
import '../theme/rango_theme.dart';
import 'checkout_components.dart';

// Forma de pagamento: as salvas no servidor; a escolha vale para o pedido.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.loading,
    required this.onBack,
    required this.onChoose,
  });

  final List<PaymentMethod> methods;
  final int? selectedId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final selected = methods.where((m) => m.id == selectedId).firstOrNull;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutHeader(title: 'Forma de pagamento', onBack: onBack),
          Expanded(
            child: loading
                ? const CheckoutLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    children: [
                      for (final method in methods) ...[
                        _MethodRow(
                          method: method,
                          selected: method.id == selectedId,
                          onTap: () => onChoose(method.id),
                        ),
                        const SizedBox(height: 11),
                      ],
                      if (selected != null && selected.type.isCard)
                        const _CardDetails(),
                    ],
                  ),
          ),
          CheckoutBottomBar(
            child: AuthSubmitButton(
              label: 'Confirmar forma de pagamento',
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SelectableRow(
      selected: selected,
      onTap: onTap,
      children: [
        SoftIcon(icon: paymentIcon(method.type), size: 42),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                method.label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                method.detail,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        RadioMark(selected: selected),
      ],
    );
  }
}

// Bloco "Dados do cartão" do protótipo. É só visual: o cartão salvo no
// servidor já tem bandeira e 4 dígitos, e o número nunca é enviado.
class _CardDetails extends StatelessWidget {
  const _CardDetails();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 11,
        children: [
          Text(
            'Dados do cartão',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const CheckoutField(
            hint: 'Número do cartão',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
          ),
          const CheckoutField(
            hint: 'Nome impresso no cartão',
            icon: Icons.person_outline_rounded,
          ),
          const CheckoutField(
            hint: 'Validade e CVV',
            icon: Icons.calendar_month_outlined,
            keyboardType: TextInputType.number,
          ),
          Row(
            spacing: 8,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: RangoColors.success,
              ),
              Flexible(
                child: Text(
                  'dados enviados por conexão segura',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Courier'],
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
