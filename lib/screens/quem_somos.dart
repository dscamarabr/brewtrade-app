import 'package:flutter/material.dart';

class TelaQuemSomos extends StatelessWidget {
  const TelaQuemSomos({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quem Somos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🖼 Imagem no topo
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Image.asset(
                  'assets/quem_somos.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                'O começo com café e código',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Texto introdutório
              Text(
                'A SlothCode Labs nasceu entre goles de café e linhas de código que insistiam em não '
                'compilar na primeira tentativa (e às vezes nem na segunda). Criada por Daniel, um '
                'entusiasta de tecnologia e cervejas artesanais, a missão sempre foi simples: transformar '
                'boas ideias em aplicativos úteis, com a paciência e a calma de um bicho-preguiça.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),

              // Outra seção
              Text(
                'Nossa Missão',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Na SlothCode Labs, acreditamos que a pressa é inimiga da perfeição… '
                'e amiga dos bugs. Nossa missão é desenvolver soluções digitais com calma, '
                'cuidado e um toque de humor, porque acreditamos que até a tecnologia '
                'funciona melhor quando não está estressada.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 24),

              Divider(color: theme.dividerColor),
              const SizedBox(height: 12),

              // Rodapé
              Text(
                'SlothCode Labs © ${DateTime.now().year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
