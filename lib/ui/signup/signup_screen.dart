import 'package:material_ui/material_ui.dart';

import '../components/auth_components.dart';

enum _SignupField {
  name(
    'Nome completo',
    'Maria Silva',
    Icons.person_outline_rounded,
    TextInputType.name,
  ),
  email(
    'E-mail',
    'voce@email.com',
    Icons.mail_outline_rounded,
    TextInputType.emailAddress,
  ),
  phone(
    'Telefone',
    '(11) 90000-0000',
    Icons.call_outlined,
    TextInputType.phone,
  ),
  password(
    'Senha',
    'Mínimo 6 caracteres',
    Icons.lock_outline_rounded,
    TextInputType.visiblePassword,
    obscure: true,
  ),
  confirmPassword(
    'Confirmar senha',
    'Repita a senha',
    Icons.lock_reset_rounded,
    TextInputType.visiblePassword,
    obscure: true,
  );

  const _SignupField(
    this.label,
    this.hint,
    this.icon,
    this.keyboardType, {
    this.obscure = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.onBack,
    required this.onSignupSuccess,
    required this.onLogin,
  });

  final VoidCallback onBack;
  final VoidCallback onSignupSuccess;
  final VoidCallback onLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _controllers = {
    for (final field in _SignupField.values) field: TextEditingController(),
  };
  var _acceptedTerms = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() => widget.onSignupSuccess();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                spacing: 12,
                children: [
                  AuthBackButton(onPressed: widget.onBack),
                  Text(
                    'Criar conta',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    for (final field in _SignupField.values)
                      AuthField(
                        label: field.label,
                        controller: _controllers[field]!,
                        hint: field.hint,
                        icon: field.icon,
                        obscureText: field.obscure,
                        keyboardType: field.keyboardType,
                        textInputAction: field == _SignupField.confirmPassword
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: field == _SignupField.confirmPassword
                            ? (_) => _submit()
                            : null,
                      ),
                    _TermsRow(
                      checked: _acceptedTerms,
                      onToggle: () =>
                          setState(() => _acceptedTerms = !_acceptedTerms),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Opacity(
                        opacity: _acceptedTerms ? 1 : .55,
                        child: AuthSubmitButton(
                          label: 'Criar conta',
                          onPressed: _submit,
                        ),
                      ),
                    ),
                    AuthFooter(
                      prompt: 'Já tem conta?',
                      action: 'Entrar',
                      onAction: widget.onLogin,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = TextStyle(
      color: colors.primary,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      checked: checked,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              AuthCheckbox(checked: checked),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Li e aceito os '),
                      TextSpan(text: 'Termos de uso', style: highlight),
                      const TextSpan(text: ' e a '),
                      TextSpan(
                        text: 'Política de privacidade',
                        style: highlight,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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
