import 'package:material_ui/material_ui.dart';

import '../../data/checkout.dart';
import '../components/auth_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'checkout_components.dart';

typedef SaveAddress = Future<Map<String, String>> Function(AddressForm form);

// Endereço de entrega: escolher um salvo ou cadastrar um novo.
class AddressScreen extends StatefulWidget {
  const AddressScreen({
    super.key,
    required this.addresses,
    required this.selectedId,
    required this.loading,
    required this.onBack,
    required this.onChoose,
    required this.onSave,
    required this.onConfirm,
  });

  final List<Address> addresses;
  final int? selectedId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<int> onChoose;
  final SaveAddress onSave;
  // "Usar este endereço".
  final Future<bool> Function() onConfirm;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

// Campos do formulário. O protótipo junta bairro e cidade num campo só,
// mas a API pede os dois separados.
const _fields = [
  (key: 'cep', hint: 'CEP', keyboard: TextInputType.number),
  (key: 'street', hint: 'Rua e número', keyboard: TextInputType.streetAddress),
  (key: 'complement', hint: 'Complemento', keyboard: TextInputType.text),
  (key: 'neighborhood', hint: 'Bairro', keyboard: TextInputType.text),
  (key: 'city', hint: 'Cidade', keyboard: TextInputType.text),
];

class _AddressScreenState extends State<AddressScreen> {
  final _controllers = {
    for (final f in _fields) f.key: TextEditingController(),
  };
  var _formOpen = false;
  var _saving = false;
  var _confirming = false;
  var _errors = <String, String>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _controllers[key]!.text.trim();

  // Erros simples antes de chamar o servidor; o resto vem da API.
  Map<String, String> _validate() => {
    if (_text('cep').replaceAll(RegExp(r'\D'), '').length != 8)
      'cep': 'CEP inválido.',
    if (_text('street').isEmpty) 'street': 'Informe rua e número.',
    if (_text('neighborhood').isEmpty) 'neighborhood': 'Informe o bairro.',
    if (_text('city').isEmpty) 'city': 'Informe a cidade.',
  };

  Future<void> _save() async {
    final errors = _validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    final serverErrors = await widget.onSave(
      AddressForm(
        cep: _text('cep'),
        street: _text('street'),
        complement: _text('complement'),
        neighborhood: _text('neighborhood'),
        city: _text('city'),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _errors = serverErrors;
      if (serverErrors.isEmpty) {
        _formOpen = false;
        for (final c in _controllers.values) {
          c.clear();
        }
      }
    });
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final saved = await widget.onConfirm();
    if (!mounted) return;
    setState(() => _confirming = false);
    if (saved) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutHeader(title: 'Endereço de entrega', onBack: widget.onBack),
          Expanded(
            child: widget.loading
                ? const CheckoutLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    children: [
                      const _MapPlaceholder(),
                      for (final address in widget.addresses) ...[
                        const SizedBox(height: 12),
                        _AddressRow(
                          address: address,
                          selected: address.id == widget.selectedId,
                          onTap: () => widget.onChoose(address.id),
                        ),
                      ],
                      if (_formOpen) ...[
                        const SizedBox(height: 12),
                        _NewAddressForm(
                          controllers: _controllers,
                          errors: _errors,
                          saving: _saving,
                          onChanged: (key) {
                            if (_errors.containsKey(key)) {
                              setState(
                                () => _errors = {..._errors}..remove(key),
                              );
                            }
                          },
                          onSave: _save,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _AddButton(
                        open: _formOpen,
                        onTap: () => setState(() {
                          _formOpen = !_formOpen;
                          _errors = {};
                        }),
                      ),
                    ],
                  ),
          ),
          CheckoutBottomBar(
            child: AuthSubmitButton(
              label: 'Usar este endereço',
              loading: _confirming,
              onPressed: widget.loading || _confirming ? () {} : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

// Mapa provisório do protótipo: verde claro com listras e o pino.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 132,
        child: CustomPaint(
          painter: StripesPainter(
            color: oklch(0.86, 0.03, 160, 0.7),
            stripe: const Color(0x0D000000),
            width: 10,
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 34,
                  color: RangoColors.error,
                  semanticLabel: 'Localização',
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'mapa · localização',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: ['Courier'],
                      fontSize: 9.5,
                      color: Color(0x80000000),
                    ),
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

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SelectableRow(
      selected: selected,
      onTap: onTap,
      children: [
        RadioMark(selected: selected),
        Expanded(
          child: Column(
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Ícone do protótipo; editar endereço não faz parte desta feature.
        ExcludeSemantics(
          child: Icon(
            Icons.edit_outlined,
            size: 19,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NewAddressForm extends StatelessWidget {
  const _NewAddressForm({
    required this.controllers,
    required this.errors,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  final Map<String, TextEditingController> controllers;
  final Map<String, String> errors;
  final bool saving;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      border: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 11,
        children: [
          Text(
            'Novo endereço',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final field in _fields)
            CheckoutField(
              hint: field.hint,
              controller: controllers[field.key],
              keyboardType: field.keyboard,
              error: errors[field.key],
              onChanged: (_) => onChanged(field.key),
            ),
          FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: colors.primary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.7),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(saving ? 'Salvando...' : 'Salvar endereço'),
          ),
        ],
      ),
    );
  }
}

// "Cadastrar novo endereço", com borda tracejada como no protótipo.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);

    return CustomPaint(
      foregroundPainter: _DashedRect(color: colors.outline, radius: 16),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                const Icon(
                  Icons.add_location_alt_outlined,
                  size: 20,
                  color: RangoColors.primary,
                ),
                Text(
                  'Cadastrar novo endereço',
                  semanticsLabel: open
                      ? 'Fechar cadastro de endereço'
                      : 'Cadastrar novo endereço',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13.5,
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

class _DashedRect extends CustomPainter {
  const _DashedRect({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRect old) =>
      old.color != color || old.radius != radius;
}
