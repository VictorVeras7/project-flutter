import 'package:material_ui/material_ui.dart';

import '../../data/checkout.dart';
import '../components/auth_components.dart';
import '../theme/rango_theme.dart';

// Peças repetidas nas telas de checkout, endereço e pagamento do protótipo.

// Ícone de cada forma de pagamento, como no protótipo.
IconData paymentIcon(PaymentType type) => switch (type) {
  PaymentType.pix => Icons.qr_code_2_rounded,
  PaymentType.credit => Icons.credit_card_rounded,
  PaymentType.debit => Icons.credit_score_rounded,
  PaymentType.cash => Icons.payments_outlined,
};

// Cabeçalho com voltar e título.
class CheckoutHeader extends StatelessWidget {
  const CheckoutHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra de baixo com o botão principal da tela.
class CheckoutBottomBar extends StatelessWidget {
  const CheckoutBottomBar({super.key, required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

// Cartão branco com borda, usado nos blocos do checkout.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = 15,
    this.border,
  });

  final Widget child;
  final double padding;
  // Borda de destaque (formulário de endereço novo).
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border ?? colors.outline,
          width: border == null ? 1 : 1.5,
        ),
      ),
      child: child,
    );
  }
}

class RadioMark extends StatelessWidget {
  const RadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
              ),
            )
          : null,
    );
  }
}

// Linha de escolha única (endereço ou forma de pagamento).
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.selected,
    required this.onTap,
    required this.children,
  });

  final bool selected;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(17);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? RangoPalette.of(context).soft : colors.surface,
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
            padding: const EdgeInsets.all(14),
            child: Row(spacing: 12, children: children),
          ),
        ),
      ),
    );
  }
}

// Ícone laranja sobre fundo claro (forma de pagamento).
class SoftIcon extends StatelessWidget {
  const SoftIcon({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: RangoPalette.of(context).soft,
        borderRadius: BorderRadius.circular(size > 40 ? 14 : 13),
      ),
      child: Icon(icon, size: size > 40 ? 22 : 21, color: RangoColors.primary),
    );
  }
}

// Campo simples dos formulários do checkout (endereço novo e cartão).
class CheckoutField extends StatelessWidget {
  const CheckoutField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.error,
    this.keyboardType,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = this.error;
    const style = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null ? colors.error : colors.outline,
            ),
          ),
          child: Row(
            spacing: 10,
            children: [
              if (icon != null)
                Icon(icon, size: 18, color: colors.onSurfaceVariant),
              Expanded(
                child: Semantics(
                  label: hint,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textInputAction: TextInputAction.next,
                    onChanged: onChanged,
                    style: style.copyWith(color: colors.onSurface),
                    decoration: InputDecoration.collapsed(
                      hintText: hint,
                      hintStyle: style.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Text(
            error,
            style: TextStyle(
              color: colors.error,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// Carregamento no lugar do conteúdo enquanto as listas chegam.
class CheckoutLoading extends StatelessWidget {
  const CheckoutLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: RangoColors.primary),
    );
  }
}
