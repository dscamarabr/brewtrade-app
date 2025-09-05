import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';


import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';

import 'package:brewtrade_app/widgets/CustomEmailField.dart';
import 'package:brewtrade_app/screens/confirmacao_email.dart';
import 'package:brewtrade_app/screens/menu_principal.dart';
import 'package:brewtrade_app/screens/recuperar_senha.dart';
import 'package:brewtrade_app/services/perfil_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  bool isLogin = true;
  bool loading = false;

  String _appVersion = '';

  // Controle de token para evitar envios duplicados + listener
  String? _ultimoTokenEnviado;
  StreamSubscription<String>? _tokenSub;

  String getFriendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Hmm... esse login não bateu. Confere aí o e-mail ou a senha e tenta de novo 🍺';
    } else if (message.contains('password should be at least 6 characters')) {
      return 'Ops! Sua senha tá muito curtinha. Tenta uma com pelo menos 6 caracteres 😉';
    } else if (message.contains('user already registered') ||
        message.contains('duplicate key value') ||
        message.contains('users_email_key')) {
      return 'Esse e-mail já está cadastrado 📨';
    } else if (message.contains('email_not_confirmed')) {
      return 'Quase lá! Confirma seu e-mail pra liberar o acesso ✨';
    }

    return 'Algo deu errado. Tente novamente mais tarde ou confira os dados 😕';
  }

  // Pede permissão (iOS e afins). No Android pode não exibir prompt, mas é seguro chamar.
  Future<void> _ensurePushPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _enviarToken(String token) async {
    if (token.isEmpty || token == _ultimoTokenEnviado) return;

    final supaAuth = Supabase.instance.client.auth;
    final user = supaAuth.currentUser;
    if (user == null) return;

    final session = supaAuth.currentSession;

    try {
      await http.post(
        Uri.parse('https://zkkctbgvbsevfjpnvwfe.supabase.co/functions/v1/save-push-token'),
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: json.encode({
          'user_id': user.id,
          'token': token,
        }),
      );
      _ultimoTokenEnviado = token;
    } catch (_) {
      // Opcional: log/telemetria
    }
  }

  Future<void> _capturarEEnviarTokenInicial() async {
    if (!kIsWeb) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _enviarToken(token);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _appVersion = 'v${info.version}+${info.buildNumber}';
      });
    });    

    // Listener para mudanças de token (reinstalação, refresh, etc.)
    if (!kIsWeb) {
      _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _enviarToken(newToken);
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _tokenSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!mounted) return;
    setState(() => loading = true);

    final email = emailController.text.trim();
    final password = passwordController.text;
    final auth = Supabase.instance.client.auth;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato de e-mail inválido. Verifique e tente novamente 📧')),
        );
        setState(() => loading = false);
      }
      return;
    }

    if (!isLogin && password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sua senha precisa ter pelo menos 6 caracteres 💪')),
        );
        setState(() => loading = false);
      }
      return;
    }

    try {
      if (isLogin) {
        await auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'meuapp://login-callback',
        );
        final user = response.user;

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao criar a conta. Verifique os dados ou tente novamente 🛠️')),
            );
            setState(() => loading = false);
          }
          return;
        }

        if (user.identities == null || user.identities!.isEmpty) {
          if (mounted) {
            _showAccountExistsDialog(email);
            setState(() => loading = false);
          }
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EmailConfirmationScreen(email: email),
              ),
            );
          }
        });
        return;
      }

      final user = auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível obter os dados do usuário 😕')),
          );
          setState(() => loading = false);
        }
        return;
      }

      // Consulta o campo is_super_admin na tabela auth.users
      final response = await Supabase.instance.client
          .from('user_admin_status') // ou a view que expõe auth.users
          .select('is_super_admin')
          .eq('id', user.id)
          .maybeSingle();

      final bool isAdmin = response != null && response['is_super_admin'] == true;

      // Aqui você pode salvar no PerfilProvider
      if (mounted) {
        context.read<PerfilProvider>().atualizarPerfil({
          'is_super_admin': isAdmin,
        });
      }

      // 1) Garante permissão de push
      await _ensurePushPermission();
      // 2) Envia o token atual imediatamente
      await _capturarEEnviarTokenInicial();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MenuPrincipal()),
          );
        }
      });
    } catch (e) {
      final message = e.toString().toLowerCase();

      if (mounted) {
        if (message.contains('user already registered') ||
            message.contains('duplicate key value') ||
            message.contains('users_email_key')) {
          _showAccountExistsDialog(emailController.text.trim());
        } else if (message.contains('email_not_confirmed')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailConfirmationScreen(email: emailController.text.trim()),
                ),
              );
            }
          });
        } else {
          final friendlyMessage = getFriendlyErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyMessage)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showAccountExistsDialog(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conta já existe 🚨'),
        content: const Text('Esse e-mail já está ativo. Você pode fazer login ou recuperar a senha.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecuperarSenhaScreen(email: email),
                ),
              );
            },
            child: const Text('Recuperar senha'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fazer login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/login.png', fit: BoxFit.contain),
              ),
            ),
              const SizedBox(height: 32),
              Text(
                isLogin ? 'Login BrewTrade 🍺' : 'Criar Conta BrewTrade 🍻',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Entre para explorar o mundo BrewTrade'
                    : 'Junte-se a nós e comece agora',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomEmailField(controller: emailController),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      if (isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecuperarSenhaScreen(
                                    email: emailController.text.trim(),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Esqueceu sua senha? 🔑'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            loading
                                ? 'Carregando...'
                                : (isLogin ? 'Entrar' : 'Criar Conta'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => isLogin = !isLogin),
                        child: Text(
                          isLogin
                              ? 'Ainda não tem conta? Criar'
                              : 'Já tem conta? Entrar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: 0.5,
                child: Text(
                  _appVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
