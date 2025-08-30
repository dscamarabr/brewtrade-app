import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;
  const EmailConfirmationScreen({required this.email});

  Future<void> _reenviarEmail(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.resend(
        email: email,
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
              // 🖼 Imagem no topo
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/confirmacao_email.png', // substitua pela sua imagem
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
                'Enviamos um link de confirmação para:\n$email\n\nClique nele para liberar o acesso.',
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
                          onPressed: () => _reenviarEmail(context),
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
