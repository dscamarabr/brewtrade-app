import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, this.email});

  final String? email;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      emailController.text = widget.email!;
    }
  }

  Future<void> _recuperarSenha() async {
    setState(() => loading = true);
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail inválido. Confere aí 🍺')),
      );
      setState(() => loading = false);
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Verifique seu e-mail 📬'),
          content: Text('Se o e-mail estiver cadastrado, você receberá um link de recuperação.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Ok')),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao enviar recuperação de senha: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao tentar recuperar senha 😕')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha 🔐')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _recuperarSenha,
              child: Text(loading ? 'Enviando...' : 'Enviar link de recuperação'),
            ),
          ],
        ),
      ),
    );
  }
}
