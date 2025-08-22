import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/cervejeiro_provider.dart';

import 'detalhes_cervejeiro_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cervejeiros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onVoltar?.call(),
        ),
        actions: [_menuFiltroEstado(context)],
      ),
      body: lista.isEmpty
          ? _telaVazia()
          : ListView(
              children: agruparCervejeiros(provider).entries
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
                          ...entry.value.map((c) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _cardCervejeiro(c, provider),
                              )),
                        ],
                      ))
                  .toList(),
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
              'assets/sem_cervejeiros.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum cervejeiro disponível no momento',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
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
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: status == 'aceito'
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhesCervejeiroScreen(cervejeiro: cervejeiro),
                      ),
                    );
                  }
                : null,
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
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
            title: Text(
              cervejeiro.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              (cervejeiro.cidade != null && cervejeiro.cidade!.isNotEmpty)
                  ? '${cervejeiro.cidade} - ${cervejeiro.estado}'
                  : cervejeiro.estado,
            ),
            trailing: _acoesAmizade(amizade, cervejeiro, provider),
          ),
        );
      },
    );
  }

  Widget _acoesAmizade(
    Map<String, dynamic>? amizade,
    Cervejeiro cervejeiro,
    CervejeiroProvider provider,
  ) {
    const iconSize = 40.0;
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;

    if (amizade == null) {
      return IconButton(
        icon: SvgPicture.asset(
          'assets/icons/criar_amizade.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
        tooltip: 'Criar amizade',
        onPressed: () async {
          await provider.enviarConviteAmizade(cervejeiro.id, context);
          await provider.atualizarCervejeiros();
        },
      );
    }

    final status = amizade['status'];
    final idA = amizade['id_cervejeiro_a'];

    if (status == 'pendente') {
      if (idA == usuarioAtual) {
        // Você enviou o pedido → aguarda + cancelar
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/aguardar_solicitacao_amizade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
              ),
              onPressed: null,
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/cancelar_solicitacao_amizade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              tooltip: 'Cancelar solicitação',
              onPressed: () async {
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
        // Você recebeu o pedido → aceitar + recusar
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/aceitar_solicitacao_amizade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
              ),
              tooltip: 'Aceitar amizade',
              onPressed: () async {
                await provider.atualizarStatusAmizade(cervejeiro.id, 'aceito', context);
                await provider.atualizarCervejeiros();
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/recusar_solicitacao_amizade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              tooltip: 'Recusar amizade',
              onPressed: () async {
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
      // Amizade → ver cervejas + desfazer
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/lista_cervejas.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.srcIn),
            ),
            tooltip: 'Ver cervejas do amigo',
            onPressed: () => widget.onVerCervejasDoAmigo?.call(cervejeiro.id),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/desfazer_amizade.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(Colors.redAccent, BlendMode.srcIn),
            ),
            tooltip: 'Desfazer amizade',
            onPressed: () async {
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
        // Você enviou e foi recusado → mostra ícone de "recusado" + botão para excluir o registro
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/recusado_amizade.svg', // ícone que podemos criar no mesmo estilo
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              onPressed: null, // apenas informativo
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/cancelar_solicitacao_amizade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
              tooltip: 'Cancelar solicitação',
              onPressed: () async {
                await provider.removerAmizade(cervejeiro.id, context);
                await provider.atualizarCervejeiros();
              },
            ),
          ],
        );
      } else {
        // O outro enviou e você recusou → só mostra o status recusado
        return IconButton(
          icon: SvgPicture.asset(
            'assets/icons/recusado_amizade.svg',
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
          ),
          onPressed: null,
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
}
