import 'package:material_ui/material_ui.dart';

import '../theme/rango_theme.dart';

final _emailPattern = RegExp(
  r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$',
  caseSensitive: false,
);

bool isValidEmail(String email) => _emailPattern.hasMatch(email);

enum RangoToastKind {
  success(Icons.check_circle_rounded, Color(0xFF31C25C)),
  error(Icons.error_rounded, Color(0xFFFF5F58)),
  info(Icons.info_rounded, Color(0xFFFF8A34));

  const RangoToastKind(this.icon, this.accent);

  final IconData icon;
  final Color accent;
}

void showRangoToast(
  BuildContext context,
  String message, {
  RangoToastKind kind = RangoToastKind.success,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2600),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: EdgeInsets.zero,
        elevation: 10,
        // A cor de fundo aparece só nos 3 px da faixa lateral do protótipo.
        backgroundColor: kind.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2E33) : const Color(0xFF26262A),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            spacing: 10,
            children: [
              Icon(kind.icon, size: 20, color: Colors.white),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      tooltip: 'Voltar',
      iconSize: 21,
      icon: const Icon(Icons.arrow_back_rounded),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: colors.onSurface,
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.error,
    this.valid = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? error;
  final bool valid;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = this.error;
    final borderColor = error != null
        ? colors.error
        : valid
        ? RangoColors.success
        : colors.outline;
    const inputStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 7,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            spacing: 10,
            children: [
              Icon(icon, size: 19, color: colors.onSurfaceVariant),
              Expanded(
                child: Semantics(
                  label: label,
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    autocorrect: false,
                    enableSuggestions: !obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: inputStyle.copyWith(color: colors.onSurface),
                    decoration: InputDecoration.collapsed(
                      hintText: hint,
                      hintStyle: inputStyle.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              if (valid)
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 19,
                  color: RangoColors.success,
                ),
              ?trailing,
            ],
          ),
        ),
        if (error != null)
          Row(
            spacing: 6,
            children: [
              Icon(Icons.error_outline_rounded, size: 15, color: colors.error),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: checked ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: checked ? colors.primary : colors.outline,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.success = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: success ? RangoColors.success : colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 9,
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
                backgroundColor: Color(0x59FFFFFF),
              ),
            ),
          if (success) const Icon(Icons.check_circle_outline_rounded, size: 22),
          // Rótulos longos ("Processando pagamento...") não estouram em tela estreita.
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: theme.colorScheme.primary,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.prompt,
    required this.action,
    required this.onAction,
  });

  final String prompt;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          prompt,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        AuthTextLink(label: action, onPressed: onAction),
      ],
    );
  }
}
