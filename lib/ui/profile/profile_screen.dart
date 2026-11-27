import 'package:material_ui/material_ui.dart';

import '../../data/profile.dart';
import '../checkout/checkout_components.dart';
import '../settings/settings_components.dart';
import '../theme/rango_theme.dart';

// Perfil: dados da conta e atalhos para as outras telas.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.unreadCount,
    required this.addressCount,
    required this.paymentCount,
    required this.theme,
    required this.onLoad,
    required this.onOpenNotifications,
    required this.onEditProfile,
    required this.onAddresses,
    required this.onPayments,
    required this.onSettings,
    required this.onTheme,
    required this.onHelp,
    required this.onLogout,
  });

  // null = carregando.
  final Profile? profile;
  final int unreadCount;
  final int addressCount;
  final int paymentCount;
  final ThemePreference theme;
  // Recarrega sempre que a aba abre.
  final VoidCallback onLoad;
  final VoidCallback onOpenNotifications;
  final VoidCallback onEditProfile;
  final VoidCallback onAddresses;
  final VoidCallback onPayments;
  final VoidCallback onSettings;
  final VoidCallback onTheme;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.onLoad();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final rows = [
      (
        Icons.person_outline_rounded,
        'Editar perfil',
        'nome, e-mail e telefone',
        widget.onEditProfile,
      ),
      (
        Icons.location_on_outlined,
        'Endereços',
        addressCountLabel(widget.addressCount),
        widget.onAddresses,
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Formas de pagamento',
        paymentCountLabel(widget.paymentCount),
        widget.onPayments,
      ),
      (Icons.settings_outlined, 'Configurações', '', widget.onSettings),
      (
        Icons.notifications_none_rounded,
        'Notificações',
        unreadLabel(widget.unreadCount),
        widget.onOpenNotifications,
      ),
      (Icons.dark_mode_outlined, 'Tema', widget.theme.label, widget.onTheme),
      (Icons.help_outline_rounded, 'Ajuda', '', widget.onHelp),
    ];

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: profile == null
          ? const CheckoutLoading()
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(
                  profile: profile,
                  hasUnread: widget.unreadCount > 0,
                  onOpenNotifications: widget.onOpenNotifications,
                  onEditProfile: widget.onEditProfile,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      for (final (icon, label, hint, onTap) in rows)
                        ProfileRowCard(
                          row: SettingsRow(
                            icon: icon,
                            label: label,
                            hint: hint,
                            onTap: onTap,
                          ),
                        ),
                      ProfileRowCard(
                        danger: true,
                        row: SettingsRow(
                          icon: Icons.logout_rounded,
                          label: 'Sair da conta',
                          danger: true,
                          chevron: false,
                          onTap: widget.onLogout,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.hasUnread,
    required this.onOpenNotifications,
    required this.onEditProfile,
  });

  final Profile profile;
  final bool hasUnread;
  final VoidCallback onOpenNotifications;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 15,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Perfil',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  _BellButton(hasUnread: hasUnread, onTap: onOpenNotifications),
                ],
              ),
              Row(
                spacing: 14,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RangoPalette.of(context).soft,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(profile.email, style: detail),
                        if (profile.phone.isNotEmpty)
                          Text(profile.phone, style: detail),
                      ],
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: onEditProfile,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
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
                child: const Text('Editar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sino com o ponto vermelho quando há notificação não lida.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(color: colors.outline),
    );

    return Semantics(
      container: true,
      button: true,
      label: hasUnread ? 'Notificações não lidas' : 'Notificações',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: colors.onSurface,
                ),
                if (hasUnread)
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
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
