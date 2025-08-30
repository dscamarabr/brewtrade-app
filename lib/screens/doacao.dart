import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelaDoacao extends StatefulWidget {
  const TelaDoacao({Key? key}) : super(key: key);

  @override
  _TelaDoacaoState createState() => _TelaDoacaoState();
}

class _TelaDoacaoState extends State<TelaDoacao> {
  final String chavePix = 'slothcodelabs@gmail.com';

  void _copiarChavePix() {
    Clipboard.setData(ClipboardData(text: chavePix));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chave Pix copiada com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apoie o Projeto'),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🦥 Imagem menor e centralizada
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Image.asset(
                'assets/doacao.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // 📌 Por que doar?
            Text(
              'Por que doar?',
              style: theme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Com sua ajuda, podemos manter o app gratuito, evoluir com novas funções e continuar apoiando o desenvolvimento independente.',
              style: theme.bodyMedium?.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 💡 Como o valor será usado
            Row(
              children: [
                Icon(Icons.favorite, color: colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Como o valor será usado:',
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '• Custos de hospedagem e servidores\n'
              '• Desenvolvimento de novas funcionalidades\n'
              '• Suporte, manutenção e melhorias contínuas',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 30),

            // 🔑 Chave Pix
            Row(
              children: [
                Icon(Icons.key, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Chave Pix:',
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      chavePix,
                      style: theme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copiar chave',
                    onPressed: _copiarChavePix,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 💛 Mensagem de agradecimento
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💛 Obrigado por apoiar o projeto!',
                style: theme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}