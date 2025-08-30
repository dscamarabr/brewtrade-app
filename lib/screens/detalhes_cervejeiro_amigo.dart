import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/cervejeiro_provider.dart';

class DetalhesCervejeiroScreen extends StatelessWidget {
  final Cervejeiro cervejeiro;

  const DetalhesCervejeiroScreen({required this.cervejeiro, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(cervejeiro.nome),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: (cervejeiro.fotoUrl != null && cervejeiro.fotoUrl!.isNotEmpty)
                        ? Image.network(
                            cervejeiro.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Image(image: AssetImage('assets/imagem_padrao.png')),
                          )
                        : const Image(image: AssetImage('assets/imagem_padrao.png')),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _infoItem('Nome', cervejeiro.nome, theme),
            _infoItem('Estado', cervejeiro.estado, theme),

            if (cervejeiro.cidade != null && cervejeiro.cidade!.isNotEmpty)
              _infoItem('Cidade', cervejeiro.cidade!, theme),

            if (cervejeiro.telefone.isNotEmpty)
              _infoItem(
                'Telefone',
                cervejeiro.telefone,
                theme,
                svgIconPath: 'assets/icons/whatsapp.svg',
                onTap: () {
                  final numero = cervejeiro.telefone.replaceAll(RegExp(r'\D'), '');
                  final numeroFormatado = numero.startsWith('55') ? numero : '55$numero';
                  final url = Uri.parse('https://wa.me/$numeroFormatado');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),

            if (cervejeiro.cervejaria != null && cervejeiro.cervejaria!.isNotEmpty)
              _infoItem('Cervejaria', cervejeiro.cervejaria!, theme),

            if (cervejeiro.bio != null && cervejeiro.bio!.isNotEmpty)
              _infoItem('Bio', cervejeiro.bio!, theme),

            if (cervejeiro.redeSocial != null && cervejeiro.redeSocial!.isNotEmpty)
              _infoItem(
                'Instagram',
                cervejeiro.redeSocial!,
                theme,
                svgIconPath: 'assets/icons/instagram.svg',
                onTap: () {
                  final username = cervejeiro.redeSocial!
                      .trim()
                      .replaceAll('@', '');
                  final url = Uri.parse('https://instagram.com/$username');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
    String label,
    String value,
    ThemeData theme, {
    VoidCallback? onTap,
    String? svgIconPath,
  }) {
    final isLink = onTap != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (svgIconPath != null)
                  SvgPicture.asset(
                    svgIconPath,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                if (svgIconPath != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isLink ? theme.colorScheme.primary : null,
                      fontWeight: isLink ? FontWeight.w600 : FontWeight.w400,
                    ),
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
