import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../services/cerveja_amigos_provider.dart';
import 'detalhe_cervejas_amigos.dart';

class TelaCervejasAmigos extends StatefulWidget {
  final String? idCervejeiro;
  final void Function()? onVoltar;
  final String origem;

  const TelaCervejasAmigos({
    super.key,
    this.idCervejeiro,
    this.onVoltar,
    this.origem = "menu",
  });

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

  void _voltar() {
    if (widget.onVoltar != null) {
      widget.onVoltar!();
      return;
    }

    switch (widget.origem) {
      case "menu":
        Navigator.of(context).pushReplacementNamed('/menuPrincipal');
        break;
      case "amigos":
        Navigator.of(context).pushReplacementNamed('/explorarCervejeiros');
        break;
      case "notificacoes":
        Navigator.of(context).pushReplacementNamed('/notificacoes');
        break;
      default:
        Navigator.of(context).pop();
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
          onPressed: _voltar,
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
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TelaDetalhesCerveja(cerveja: cerveja),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              cerveja.imagens?.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        cerveja.imagens!.first,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.broken_image, size: 48);
                                        },
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/icons/garrafa_cerveja.svg',
                                      width: 56,
                                      height: 56,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.brown,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cerveja.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cervejeiro: ${cerveja.descricao ?? 'Desconhecido'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cadastrada em  ${DateFormat('dd/MM/yyyy').format(cerveja.data_cadastro)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Chip(
                                          label: Text(cerveja.estilo),
                                          backgroundColor: Colors.orange.withOpacity(0.1),
                                        ),
                                        Chip(
                                          label: Text('${cerveja.abv.toStringAsFixed(1)}% ABV'),
                                          backgroundColor: Colors.blue.withOpacity(0.1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : _telaVazia(),
      ),
    );
  }

  Widget _telaVazia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/sem_cervejas.png',
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOrdenacao(BuildContext context) {
    final provider = Provider.of<CervejaAmigosProvider>(context, listen: false);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: provider.atualizarOrdenacao,
      itemBuilder: (_) =>
          ['Nome', 'Estilo', 'ABV', 'Cervejeiro','Data'].map((ord) => PopupMenuItem(value: ord, child: Text(ord))).toList(),
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
