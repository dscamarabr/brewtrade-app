import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- importar
import '../models/cerveja.dart';

class TelaDetalhesCerveja extends StatelessWidget {
  final Cerveja cerveja;

  const TelaDetalhesCerveja({
    Key? key,
    required this.cerveja,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imagens = cerveja.imagens ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(cerveja.nome),
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
            if (imagens.isNotEmpty) _CarrosselImagens(imagens: imagens),

            const SizedBox(height: 24),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoLinha(icone: 'assets/icons/cervejaria.svg', titulo: 'Cervejaria', valor: cerveja.cervejaria),
                    _infoLinha(icone: 'assets/icons/estilo_cerveja.svg', titulo: 'Estilo', valor: cerveja.estilo),
                    _infoLinha(icone: 'assets/icons/abv.svg', titulo: 'ABV', valor: '${cerveja.abv.toStringAsFixed(1)}%'),
                    _infoLinha(icone: 'assets/icons/lupulo.svg', titulo: 'IBU', valor: cerveja.ibu?.toString() ?? 'Não informado'),
                    _infoLinha(icone: 'assets/icons/garrafa_cerveja.svg', titulo: 'Volume', valor: '${cerveja.volume} ml'),
                    _infoLinha(icone: 'assets/icons/quantidade_cervejas.svg', titulo: 'Quantidade', valor: cerveja.quantidade?.toString() ?? 'Não informada'),

                    // WhatsApp do dono (busca em tb_cervejeiro usando id_usuario da cerveja)
                    FutureBuilder<Map<String, String>?>(
                      future: _buscarContatoDono(cerveja.id_usuario),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final contato = snap.data;
                        if (contato == null) {
                          return const SizedBox.shrink();
                        }
                        final telefone = contato['telefone']!;
                        final nomeDono = contato['nome'];

                        return _infoLinha(
                          icone: 'assets/icons/whatsapp.svg',
                          titulo: 'Contato',
                          valor: telefone,
                          onTap: () {
                            final numero = telefone.replaceAll(RegExp(r'\D'), '');
                            final numeroFormatado = numero.startsWith('55') ? numero : '55$numero';

                            final msg = 'Olá${nomeDono != null && nomeDono.isNotEmpty ? ', ${nomeDono.split(' ').first}' : ''}! '
                                'Vi a cerveja "${cerveja.nome}" e queria trocar uma ideia 🍺';

                            final url = Uri.parse(
                              'https://wa.me/$numeroFormatado?text=${Uri.encodeComponent(msg)}',
                            );
                            
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _infoLinha(
                  icone: Icons.description,
                  titulo: 'Descrição',
                  valor: cerveja.descricao?.trim().isNotEmpty == true ? cerveja.descricao! : 'Sem descrição',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Agora retorna um Map com telefone e nome
  Future<Map<String, String>?> _buscarContatoDono(String idUsuario) async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('tb_cervejeiro')
          .select('telefone, nome') // buscamos os dois campos
          .eq('id', idUsuario)
          .maybeSingle();

      if (data == null) return null;

      final tel = (data['telefone'] as String?)?.trim();
      final nome = (data['nome'] as String?)?.trim();

      if (tel != null && tel.isNotEmpty) {
        return {
          'telefone': tel,
          'nome': nome ?? '',
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _infoLinha({
    required dynamic icone,
    required String titulo,
    required String valor,
    VoidCallback? onTap,
  }) {
    const double tamanhoIcone = 24;
    const corIcone = Colors.brown;

    final Widget widgetIcone = icone is IconData
        ? Icon(icone, size: tamanhoIcone, color: corIcone)
        : SvgPicture.asset(
            icone,
            width: tamanhoIcone,
            height: tamanhoIcone,
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            colorFilter: const ColorFilter.mode(corIcone, BlendMode.srcIn),
          );

    final textoEstilo = TextStyle(
      color: onTap != null ? Colors.green.shade700 : Colors.black87,
      fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal,
      decoration: onTap != null ? TextDecoration.underline : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widgetIcone,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(valor, style: textoEstilo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarrosselImagens extends StatelessWidget {
  final List<String> imagens;
  const _CarrosselImagens({required this.imagens});

  @override
  Widget build(BuildContext context) {
    final imagensLimitadas = imagens.take(3).toList();

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.45,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.8),
            itemCount: imagensLimitadas.length,
            itemBuilder: (context, index) {
              final url = imagensLimitadas[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.black,
                      builder: (_) {
                        return _GaleriaFullscreen(
                          imagens: imagensLimitadas,
                          initialIndex: index,
                        );
                      },
                    );
                  },
                  child: Hero(
                    tag: url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(url, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imagensLimitadas.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.brown.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GaleriaFullscreen extends StatefulWidget {
  final List<String> imagens;
  final int initialIndex;
  const _GaleriaFullscreen({
    required this.imagens,
    required this.initialIndex,
  });

  @override
  State<_GaleriaFullscreen> createState() => _GaleriaFullscreenState();
}

class _GaleriaFullscreenState extends State<_GaleriaFullscreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.imagens.length,
            itemBuilder: (context, index) {
              final url = widget.imagens[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  child: Center(
                    child: Hero(
                      tag: url,
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.imagens.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
