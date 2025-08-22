import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/cerveja_amigos_provider.dart';

import 'detalhe_cervejas_amigos.dart';


class TelaCervejasAmigos extends StatefulWidget {
  final String? idCervejeiro;
  final void Function()? onVoltar;

  const TelaCervejasAmigos({super.key, this.idCervejeiro, this.onVoltar});

  @override
  State<TelaCervejasAmigos> createState() => _TelaCervejasAmigosState();
}

class _TelaCervejasAmigosState extends State<TelaCervejasAmigos> {
  bool _carregado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_carregado) {
      final provider = Provider.of<CervejaAmigosProvider>(context, listen: false);

      Future.microtask(() async {
        try {
          await provider.carregarCervejasDosAmigos();

          if (widget.idCervejeiro != null) {
            provider.aplicarFiltroPorIdCervejeiro(widget.idCervejeiro!);
          }

          setState(() {
            _carregado = true;
          });
        } catch (e, stack) {
          print('Erro ao carregar cervejas do amigo: $e');
          print(stack);
          setState(() {
            _carregado = true; // evita travar a tela
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CervejaAmigosProvider>(context);

    if (!_carregado) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final temCervejas = provider.cervejasFiltradas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cervejas dos Amigos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onVoltar?.call();
          },
        ),
        actions: temCervejas
            ? [
                _menuFiltroEstilo(context),
                _menuFiltroCervejeiro(context),
                _menuOrdenacao(context),
              ]
            : [],
      ),
      body: SafeArea(
        child: temCervejas
            ? ListView.builder(
                itemCount: provider.cervejasFiltradas.length,
                itemBuilder: (context, index) {
                  final cerveja = provider.cervejasFiltradas[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            cerveja.imagens?.isNotEmpty == true
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      cerveja.imagens!.first,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) { return const Icon(Icons.broken_image, size: 48); },),
                                  )
                                  : SvgPicture.asset(
                                      'assets/icons/garrafa_cerveja.svg',
                                      width: 48,
                                      height: 48,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.brown, // mesma cor que usaria no ícone Material
                                        BlendMode.srcIn,
                                      ),
                                    ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cerveja.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('${cerveja.estilo} • ${cerveja.abv.toStringAsFixed(1)}% ABV'),
                                  Text('Cervejeiro: ${cerveja.descricao ?? 'Desconhecido'}'),
                                ],
                              ),
                            ),
                            IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/detalhes_cerveja.svg',
                                  width: 40,  // ajuste o tamanho conforme seu layout
                                  height: 40,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).iconTheme.color!,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              onPressed: () {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TelaDetalhesCerveja(cerveja: cerveja),
                                    ),
                                  );
                                } catch (e) {
                                  print('Erro ao abrir detalhes: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
              : _telaVazia()
      ),
    );
  }

  Widget _telaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/sem_cervejas.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Procurando cervejas… ainda nada!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Seus amigos tão te deixando na mão!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),          
        ],
      ),
    );
  }  

  Widget _menuOrdenacao(BuildContext context) {
    final provider = Provider.of<CervejaAmigosProvider>(context, listen: false);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: provider.atualizarOrdenacao,
      itemBuilder: (_) => ['Nome', 'Estilo', 'ABV', 'Cervejeiro']
          .map((ord) => PopupMenuItem(value: ord, child: Text(ord)))
          .toList(),
    );
  }

  Widget _menuFiltroEstilo(BuildContext context) {
    final provider = Provider.of<CervejaAmigosProvider>(context);
    final estilos = provider.obterEstilosDisponiveis();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_alt),
      onSelected: provider.atualizarFiltroEstilo,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'Todos', child: Text('Todos')),
        ...estilos.map((e) => PopupMenuItem(value: e, child: Text(e))),
      ],
    );
  }

  Widget _menuFiltroCervejeiro(BuildContext context) {
    final provider = Provider.of<CervejaAmigosProvider>(context);
    final nomes = provider.obterCervejeirosDisponiveis();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.people),
      onSelected: provider.atualizarFiltroCervejeiro,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'Todos', child: Text('Todos')),
        ...nomes.map((n) => PopupMenuItem(value: n, child: Text(n))),
      ],
    );
  }
}


