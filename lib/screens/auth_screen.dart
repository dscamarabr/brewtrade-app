import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:brewtrade_app/widgets/CustomEmailField.dart';
import 'package:brewtrade_app/screens/email_confirmation_screen.dart';
import 'package:brewtrade_app/screens/menu_principal.dart';
import 'package:brewtrade_app/screens/recuperar_senha_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

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

    // Listener para mudanças de token (reinstalação, refresh, etc.)
    if (!kIsWeb) {
      _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _enviarToken(newToken);
      });
    }
  }

  @override
  void dispose() {
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
        final response = await auth.signUp(email: email, password: password);
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLogin ? 'Login BrewTrade 🍺' : 'Criar Conta BrewTrade 🍻',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            CustomEmailField(controller: emailController),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _handleAuth,
              child: Text(
                loading ? 'Carregando...' : (isLogin ? 'Entrar' : 'Criar Conta'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Ainda não tem conta? Criar' : 'Já tem conta? Entrar'),
            ),
            if (isLogin)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecuperarSenhaScreen(email: emailController.text.trim()),
                    ),
                  );
                },
                child: const Text('Esqueceu sua senha? 🔑'),
              ),
          ],
        ),
      ),
    );
  }
}
