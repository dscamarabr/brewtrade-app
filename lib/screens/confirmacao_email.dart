import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String email;
  const EmailConfirmationScreen({required this.email, super.key});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _appLinks = AppLinks();

    // Captura link inicial (app fechado e aberto pelo link)
    _appLinks.getInitialAppLink().then((uri) {
      _handleIncomingLink(uri, supabase);
    });

    // Captura links recebidos com app aberto
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri, supabase);
    });
  }

  Future<void> _handleIncomingLink(Uri? uri, SupabaseClient supabase) async {
    if (uri != null && uri.queryParameters['code'] != null) {
      final code = uri.queryParameters['code']!;
      final res = await supabase.auth.exchangeCodeForSession(code);

      if (res.session != null && mounted) {
        // Força logout para obrigar login
        await supabase.auth.signOut();

        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ E-mail confirmado com sucesso!'),
            duration: Duration(seconds: 3),
          ),
        );

        // Aguarda a mensagem aparecer antes de redirecionar
        await Future.delayed(const Duration(seconds: 3));

        // Volta para tela de autenticação limpando histórico
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }

  Future<void> _reenviarEmail() async {
    try {
      await Supabase.instance.client.auth.resend(
        email: widget.email,
        type: OtpType.signup,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail reenviado com sucesso! 📩')),
      );
    } catch (e) {
      debugPrint('Erro ao reenviar confirmação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao reenviar e-mail. Tente novamente. 😓')),
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Confirmação de E-mail ✉️'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/confirmacao_email.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Confirme seu e-mail',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos um link de confirmação para:\n${widget.email}\n\nClique nele para liberar o acesso.',
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: _reenviarEmail,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          label: const Text(
                            'Reenviar confirmação',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/auth');
                        },
                        child: const Text('Já confirmou? Ir para Login'),
                      ),
                    ],
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
