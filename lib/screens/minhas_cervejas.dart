import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '/models/cerveja.dart';

import '../services/cerveja_provider.dart';

import 'cadastro_cerveja.dart';
import 'menu_principal.dart';



class TelaListaCervejas extends StatelessWidget {
  const TelaListaCervejas({super.key});

  @override
  Widget build(BuildContext context) {
    final cervejaProvider = Provider.of<CervejaProvider>(context);
    final temCervejas = cervejaProvider.cervejas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Cervejas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
              final parentState = context.findAncestorStateOfType<MenuPrincipalState>();
              parentState?.voltarParaMenu();
          },
        ),
        actions: temCervejas
            ? [
                _menuFiltroEstilo(context),
                _menuOrdenacao(context),
              ]
            : [],
      ),
      body: SafeArea(
        child: temCervejas
            ? _listaAgrupada(context, cervejaProvider)
            : _telaVaziaCentralizada(context),
      ),
    );
  }

  Map<String, List<Cerveja>> agruparPorSituacaoOrdenada(CervejaProvider provider) {
    final lista = provider.cervejasFiltradas;

    int comparator(Cerveja a, Cerveja b) {
      switch (provider.ordenacao) {
        case 'Nome':
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case 'ABV':
          return b.abv.compareTo(a.abv);
        case 'Estilo':
          return a.estilo.toLowerCase().compareTo(b.estilo.toLowerCase());
        default:
          return 0;
      }
    }

    final disponiveis = lista.where((c) => c.situacao == 'Disponível para troca').toList()..sort(comparator);
    final inativas = lista.where((c) => c.situacao == 'Inativa').toList()..sort(comparator);

    return {
      'Disponível para troca': disponiveis,
      'Inativa': inativas,
    };
  }

  Future<void> excluirImagensSupabase(List<String> urls) async {
    final client = Supabase.instance.client;

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        final index = uri.path.indexOf('/object/public/');
        if (index != -1) {
          var filePath = uri.path.substring(index + '/object/public/'.length);

          // Remover prefixo do bucket, se existir
          if (filePath.startsWith('cervejas/')) {
            filePath = filePath.replaceFirst('cervejas/', '');
          }

          await client.storage.from('cervejas').remove([filePath]);
        }
      } catch (e) {
        debugPrint('Erro ao apagar imagem do storage: $e');
      }
    }
  }

  Widget _listaAgrupada(BuildContext context, CervejaProvider provider) {
    final grupos = agruparPorSituacaoOrdenada(provider);

    return ListView(
      children: grupos.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...entry.value.map((cerveja) => Padding(
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
                                        ),
                                      )
                                      : SvgPicture.asset(
                                          'assets/icons/garrafa_cerveja.svg',
                                          width: 48,
                                          height: 48,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.brown, // mesma cor que os outros ícones
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
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${cerveja.estilo} • ${cerveja.abv.toStringAsFixed(1)}% ABV'),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'assets/icons/editar_cerveja.svg',
                                        width: 36,
                                        height: 36,
                                        colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.srcIn),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TelaCadastroCerveja(
                                              cerveja: cerveja,
                                              popAoSalvar: true,
                                              onVoltar: () {
                                                final parentState = context.findAncestorStateOfType<MenuPrincipalState>();
                                                parentState?.voltarParaMenu();
                                              },
                                            ),
                                            fullscreenDialog: true,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'assets/icons/apagar_cerveja.svg',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.srcIn),
                                      ),
                                      onPressed: () => confirmarRemocao(context, cerveja),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ))
          .toList(),
    );
  }

  void confirmarRemocao(BuildContext context, Cerveja cerveja) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover cerveja'),
        content: Text('Deseja realmente remover a cerveja "${cerveja.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (cerveja.imagens?.isNotEmpty == true) {
                await excluirImagensSupabase(cerveja.imagens!);
              }

              Provider.of<CervejaProvider>(context, listen: false).removerCerveja(cerveja);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cerveja removida com sucesso')),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Widget _telaVaziaCentralizada(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/geladeira_vazia.png',
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nada por aqui... sua geladeira está esperando.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaCadastroCerveja(),
                    fullscreenDialog: true,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar nova cerveja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuFiltroEstilo(BuildContext context) {
    final provider = Provider.of<CervejaProvider>(context);
    final estilos = provider.obterEstilosDisponiveis();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_alt),
      onSelected: (val) => provider.atualizarFiltro(val),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'Todos', child: Text('Todos')),
        ...estilos.map((estilo) =>
          PopupMenuItem(value: estilo, child: Text(estilo))
        ),
      ],
    );
  }

  Widget _menuOrdenacao(BuildContext context) {
    final provider = Provider.of<CervejaProvider>(context, listen: false);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (val) => provider.atualizarOrdenacao(val),
      itemBuilder: (_) => ['Nome', 'ABV', 'Estilo']
          .map((ord) => PopupMenuItem(value: ord, child: Text(ord)))
          .toList(),
    );
  }
}


