import 'package:shared_preferences/shared_preferences.dart';

// Endereço do back-end local: localhost nas duas plataformas, como no KMP.
// No Android, o localhost do aparelho é redirecionado para a máquina com
// `adb reverse tcp:3333 tcp:3333`. Em 10.0.2.2 o Android 17 exige a permissão
// de rede local concedida em tempo de execução, e o login trava sem ela.
const apiBaseUrl = 'http://localhost:3333';

// Guarda o refresh token entre aberturas do app, quando "Manter conectado" está marcado.
// SharedPreferences no Android e NSUserDefaults no iOS, como no KMP.
class SessionStorage {
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> readRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  // null apaga o token salvo.
  Future<void> saveRefreshToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_refreshTokenKey);
    } else {
      await prefs.setString(_refreshTokenKey, token);
    }
  }
}
