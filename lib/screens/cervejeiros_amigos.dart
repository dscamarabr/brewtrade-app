import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/cervejeiro_provider.dart';

import 'detalhes_cervejeiro_amigo.dart';
import 'cervejas_amigos.dart';
import 'tela_base.dart';

class ExplorarCervejeirosScreen extends StatefulWidget {
  final void Function(String idCervejeiro)? onVerCervejasDoAmigo;
  final void Function()? onVoltar;

  const ExplorarCervejeirosScreen({
    super.key,
    this.onVerCervejasDoAmigo,
    this.onVoltar,
  });

  @override
  State<ExplorarCervejeirosScreen> createState() => _ExplorarCervejeirosScreenState();
}

class _ExplorarCervejeirosScreenState extends State<ExplorarCervejeirosScreen> {
  String filtroStatus = 'Todos';
  bool expandirEmBusca = true;

  final opcoesFiltroStatus = ['Todos', 'Em Busca de Conexão', 'Amigos'];

  @override
  void initState() {
    super.initState();
  }

  Future<bool?> mostrarConfirmacao(BuildContext context, String mensagem) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Map<String, List<Cervejeiro>> agruparCervejeiros(CervejeiroProvider provider) {
    final lista = provider.cervejeirosFiltradosOrdenados;

    final amigos = <Cervejeiro>[];
    final outros = <Cervejeiro>[];

    for (final c in lista) {
      final status = provider.statusAmizade(c.id);
      if (status == 'aceito') {
        amigos.add(c);
      } else {
        outros.add(c);
      }
    }

    amigos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    outros.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return {
      'Em Busca de Conexão': outros,
      'Amigos': amigos,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CervejeiroProvider>();
    final lista = provider.cervejeirosFiltradosOrdenados;

    return TelaBase(
      onVoltar: () {
        if (widget.onVoltar != null) {
          widget.onVoltar!();
        } else {
          Navigator.of(context).pushReplacementNamed('/menuPrincipal');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cervejeiros Amigos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onVoltar != null) {
                widget.onVoltar!();
              } else {
                Navigator.of(context).pushReplacementNamed('/menuPrincipal');
              }
            },
          ),
          actions: [
            _menuFiltroStatus(context),
            _menuFiltroEstado(context),
          ],
        ),
        body: lista.isEmpty
            ? _telaVazia()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: agruparCervejeiros(provider).entries
                          .where((entry) {
                            if (filtroStatus == 'Todos') {
                              return entry.value.isNotEmpty;
                            }
                            return entry.key == filtroStatus &&
                                entry.value.isNotEmpty;
                          })
                          .map((entry) {
                            final titulo = entry.key;
                            final listaCervejeiros = entry.value;

                            if (titulo == 'Em Busca de Conexão') {
                              return ExpansionTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.person_add_alt,
                                        color: Colors.grey.shade800, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      titulo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                initiallyExpanded: expandirEmBusca,
                                onExpansionChanged: (expanded) {
                                  setState(() => expandirEmBusca = expanded);
                                },
                                children: listaCervejeiros
                                    .map((c) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: _cardCervejeiro(c, provider),
                                        ))
                                    .toList(),
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.shade600.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.group,
                                            color: Colors.green.shade800,
                                            size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          titulo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...listaCervejeiros.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: _cardCervejeiro(c, provider),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }
                          })
                          .toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _telaVazia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/sem_cervejeiros.png',
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum cervejeiro disponível no momento',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardCervejeiro(Cervejeiro cervejeiro, CervejeiroProvider provider) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: provider.buscarAmizade(cervejeiro.id),
      builder: (context, snapshot) {
        final amizade = snapshot.data;
        final status = amizade?['status'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: status == 'aceito'
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetalhesCervejeiroScreen(
                                            cervejeiro: cervejeiro,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text(
                                cervejeiro.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          _acoesAmizade(amizade, cervejeiro, provider, context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (cervejeiro.cidade != null && cervejeiro.cidade!.isNotEmpty)
                            ? '${cervejeiro.cidade} - ${cervejeiro.estado}'
                            : cervejeiro.estado,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _acoesAmizade(
    Map<String, dynamic>? amizade,
    Cervejeiro cervejeiro,
    CervejeiroProvider provider,
    BuildContext context,
  ) {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    const iconSize = 24.0;

    Widget buildAction(String asset, Color cor, String? tooltip, VoidCallback? onTap) {
      return IconButton(
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        icon: SvgPicture.asset(
          asset,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
        ),
        onPressed: onTap,
      );
    }

    if (amizade == null) {
      return buildAction(
        'assets/icons/criar_amizade.svg',
        Theme.of(context).primaryColor,
        'Criar amizade',
        () async {
          await provider.enviarConviteAmizade(cervejeiro.id, context);
          await provider.atualizarCervejeiros();
        },
      );
    }

    final status = amizade['status'];
    final idA = amizade['id_cervejeiro_a'];

    if (status == 'pendente') {
      if (idA == usuarioAtual) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildAction(
              'assets/icons/aguardar_solicitacao_amizade.svg',
              Colors.orange,
              'Solicitação enviada',
              null,
            ),
            const SizedBox(width: 6),
            buildAction(
              'assets/icons/cancelar_solicitacao_amizade.svg',
              Colors.red,
              'Cancelar solicitação',
              () async {
                final confirmar = await mostrarConfirmacao(
                  context,
                  'Tem certeza que deseja excluir esta solicitação de amizade?',
                );
                if (confirmar == true) {
                  await provider.removerAmizade(cervejeiro.id, context);
                  await provider.atualizarCervejeiros();
                }
              },
            ),
          ],
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildAction(
              'assets/icons/aceitar_solicitacao_amizade.svg',
              Colors.green,
              'Aceitar amizade',
              () async {
                await provider.atualizarStatusAmizade(cervejeiro.id, 'aceito', context);
                await provider.atualizarCervejeiros();
              },
            ),
            const SizedBox(width: 6),
            buildAction(
              'assets/icons/recusar_solicitacao_amizade.svg',
              Colors.red,
              'Recusar amizade',
              () async {
                final confirmar = await mostrarConfirmacao(
                  context,
                  'Deseja realmente recusar esta solicitação de amizade?',
                );
                if (confirmar == true) {
                  await provider.atualizarStatusAmizade(cervejeiro.id, 'recusado', context);
                  await provider.atualizarCervejeiros();
                }
              },
            ),
          ],
        );
      }
    }

    if (status == 'aceito') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildAction(
            'assets/icons/lista_cervejas.svg',
            Colors.brown,
            'Ver cervejas do amigo',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaCervejasAmigos(
                    idCervejeiro: cervejeiro.id,
                    origem: "amigos",
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          buildAction(
            'assets/icons/desfazer_amizade.svg',
            Colors.redAccent,
            'Desfazer amizade',
            () async {
              final confirmar = await mostrarConfirmacao(
                context,
                'Tem certeza que deseja desfazer esta amizade?',
              );
              if (confirmar == true) {
                await provider.removerAmizade(cervejeiro.id, context);
                await provider.atualizarCervejeiros();
              }
            },
          ),
        ],
      );
    }

    if (status == 'recusado') {
      if (idA == usuarioAtual) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildAction(
              'assets/icons/recusado_amizade.svg',
              Colors.red,
              null,
              null,
            ),
            const SizedBox(width: 6),
            buildAction(
              'assets/icons/cancelar_solicitacao_amizade.svg',
              Colors.red,
              'Cancelar solicitação',
              () async {
                await provider.removerAmizade(cervejeiro.id, context);
                await provider.atualizarCervejeiros();
              },
            ),
          ],
        );
      } else {
        return buildAction(
          'assets/icons/recusado_amizade.svg',
          Colors.red,
          null,
          null,
        );
      }
    }

    return const SizedBox();
  }

  Widget _menuFiltroEstado(BuildContext context) {
    final provider = Provider.of<CervejeiroProvider>(context);
    final estados = provider.estadosDisponiveis;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_alt_outlined),
      onSelected: (val) async {
        provider.aplicarFiltroEstado(val);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Todos')),
        ...estados.map(
          (estado) => PopupMenuItem(value: estado, child: Text(estado)),
        ),
      ],
    );
  }

  Widget _menuFiltroStatus(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list_alt), // ícone do filtro de status
      onSelected: (val) {
        setState(() => filtroStatus = val);
      },
      itemBuilder: (_) => opcoesFiltroStatus
          .map((status) => PopupMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
    );
  }

}
