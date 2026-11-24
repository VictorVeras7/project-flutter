import 'package:material_ui/material_ui.dart';

import '../../data/remote/api_models.dart';
import '../components/auth_components.dart';

enum _SignupField {
  name(
    'name',
    'Nome completo',
    'Maria Silva',
    Icons.person_outline_rounded,
    TextInputType.name,
  ),
  email(
    'email',
    'E-mail',
    'voce@email.com',
    Icons.mail_outline_rounded,
    TextInputType.emailAddress,
  ),
  phone(
    'phone',
    'Telefone',
    '(11) 90000-0000',
    Icons.call_outlined,
    TextInputType.phone,
  ),
  password(
    'password',
    'Senha',
    'Mínimo 6 caracteres',
    Icons.lock_outline_rounded,
    TextInputType.visiblePassword,
    obscure: true,
  ),
  confirmPassword(
    'passwordConfirmation',
    'Confirmar senha',
    'Repita a senha',
    Icons.lock_reset_rounded,
    TextInputType.visiblePassword,
    obscure: true,
  );

  const _SignupField(
    this.apiField,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType, {
    this.obscure = false,
  });

  // Nome do campo nos erros da API (`details[].field`).
  final String apiField;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
}

// Cria a conta no servidor. Devolve os erros por campo da API; vazio = sucesso.
typedef Register = Future<Map<String, String>> Function(
  RegisterRequest request,
);

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.onBack,
    required this.register,
    required this.onSignupSuccess,
    required this.onLogin,
  });

  final VoidCallback onBack;
  final Register register;
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
  var _touched = false;
  var _loading = false;
  // Erros vindos do servidor (ex.: e-mail já cadastrado); somem ao editar o campo.
  var _serverErrors = <_SignupField, String>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(_SignupField field) => _controllers[field]!.text;

  Map<_SignupField, String> _validate() {
    final password = _text(_SignupField.password);
    final confirmation = _text(_SignupField.confirmPassword);
    final digits = _text(_SignupField.phone).replaceAll(RegExp(r'\D'), '');

    return {
      ..._serverErrors,
      if (_text(_SignupField.name).trim().length < 3)
        _SignupField.name: 'Informe seu nome completo.',
      if (!isValidEmail(_text(_SignupField.email)))
        _SignupField.email: 'E-mail inválido.',
      if (digits.length < 10) _SignupField.phone: 'Telefone incompleto.',
      if (password.length < 6) _SignupField.password: 'Mínimo de 6 caracteres.',
      if (confirmation.isEmpty || confirmation != password)
        _SignupField.confirmPassword: 'As senhas não coincidem.',
    };
  }

  Future<void> _submit() async {
    if (_loading) return;

    final hasErrors = _validate().isNotEmpty;
    setState(() {
      _touched = true;
      _loading = !hasErrors && _acceptedTerms;
    });

    if (!_acceptedTerms) {
      showRangoToast(
        context,
        'Aceite os termos para continuar.',
        kind: RangoToastKind.error,
      );
    }
    if (!_loading) return;

    FocusScope.of(context).unfocus();
    final errors = await widget.register(
      RegisterRequest(
        name: _text(_SignupField.name).trim(),
        email: _text(_SignupField.email).trim(),
        phone: _text(_SignupField.phone),
        password: _text(_SignupField.password),
        passwordConfirmation: _text(_SignupField.confirmPassword),
      ),
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _serverErrors = {
        for (final field in _SignupField.values) field: ?errors[field.apiField],
      };
    });
    if (errors.isEmpty) widget.onSignupSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final errors = _touched ? _validate() : const <_SignupField, String>{};

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
                        error: errors[field],
                        valid:
                            _touched &&
                            errors[field] == null &&
                            _text(field).isNotEmpty,
                        obscureText: field.obscure,
                        keyboardType: field.keyboardType,
                        textInputAction: field == _SignupField.confirmPassword
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onChanged: (_) =>
                            setState(() => _serverErrors.remove(field)),
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
                          label: _loading ? 'Criando conta...' : 'Criar conta',
                          loading: _loading,
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
