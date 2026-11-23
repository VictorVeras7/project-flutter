import 'package:material_ui/material_ui.dart';

import '../components/auth_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onLoginSuccess,
    required this.onForgotPassword,
    required this.onSignup,
  });

  final VoidCallback onBack;
  final ValueChanged<bool> onLoginSuccess;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;
  var _keepConnected = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => widget.onLoginSuccess(_keepConnected);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: AuthBackButton(onPressed: widget.onBack),
            ),
            Expanded(
              // Mantém o rodapé no fim da tela e rola quando falta espaço.
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Bem-vinda de volta',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.9,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Entre para continuar seus pedidos.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AuthField(
                            label: 'E-mail',
                            controller: _email,
                            hint: 'voce@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          AuthField(
                            label: 'Senha',
                            controller: _password,
                            hint: 'Sua senha',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_showPassword,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            trailing: IconButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              tooltip: _showPassword
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              iconSize: 20,
                              color: colors.onSurfaceVariant,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 24,
                                height: 44,
                              ),
                              style: const ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 10,
                            children: [
                              Flexible(
                                child: _KeepConnected(
                                  checked: _keepConnected,
                                  onToggle: () => setState(
                                    () => _keepConnected = !_keepConnected,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: AuthTextLink(
                                  label: 'Esqueci minha senha',
                                  fontSize: 12.5,
                                  onPressed: widget.onForgotPassword,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 19),
                          AuthSubmitButton(
                            label: 'Entrar',
                            onPressed: _submit,
                          ),
                          const Spacer(),
                          const SizedBox(height: 22),
                          AuthFooter(
                            prompt: 'Não tem conta?',
                            action: 'Criar conta',
                            onAction: widget.onSignup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepConnected extends StatelessWidget {
  const _KeepConnected({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            AuthCheckbox(checked: checked),
            Flexible(
              child: Text(
                'Manter conectado',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
