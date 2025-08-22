import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;
  const EmailConfirmationScreen({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Confirme seu e-mail',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            const Text(
              'Enviamos um link de confirmação para seu e-mail. Clique nele pra liberar o acesso.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.resend(
                    email: email, // 👈 usando o parâmetro direto
                    type: OtpType.signup,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-mail reenviado com sucesso! 📩')),
                  );
                } catch (e) {
                  print('Erro ao reenviar confirmação: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao reenviar e-mail. Tente novamente. 😓')),
                  );
                }
              },
              child: const Text('Reenviar confirmação'),
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
    );
  }
}
