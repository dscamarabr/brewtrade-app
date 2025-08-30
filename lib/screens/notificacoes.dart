import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/notificacao_provider.dart';
import 'cervejas_amigos.dart';
import 'cervejeiros_amigos.dart';
import '../main.dart';

class TelaNotificacoes extends StatefulWidget {
  final String idUsuarioLogado;
  final VoidCallback? onVoltar;
  final Function(String idCervejeiro)? onAbrirCervejasDoAmigo;

  const TelaNotificacoes({
    required this.idUsuarioLogado,
    this.onVoltar,
    this.onAbrirCervejasDoAmigo,
    super.key,
  });

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarNotificacoes();
    });
  }

  Future<void> _carregarNotificacoes() async {
    final provider = context.read<NotificacaoProvider>();
    await provider.carregarNotificacoes(widget.idUsuarioLogado);
    // Não precisa mais do setState nem do _backup
  }

  void _voltar() {
    if (widget.onVoltar != null) {
      widget.onVoltar!();
    } else {
      Navigator.of(context).pushReplacementNamed('/menuPrincipal');
    }
  }

/*   void _abrirTelaCervejas(BuildContext context, String idCervejeiro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCervejasAmigos(
          idCervejeiro: idCervejeiro,
          origem: "notificacoes",
        ),
      ),
    );
  } */

  Widget _telaVaziaCentralizada(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/sem_notificacoes.png',
            width: MediaQuery.of(context).size.width * 0.6,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;

    return Consumer<NotificacaoProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificações'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _voltar,
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (tipo) {
                  if (tipo == 'Todos') {
                    provider.restaurarLista();
                  } else {
                    provider.filtrarPorTipo(tipo);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Todos', child: Text('Todos')),
                  PopupMenuItem(value: 'amizade', child: Text('Amizade')),
                  PopupMenuItem(value: 'cadastro cerveja', child: Text('Cerveja')),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.person),
                onSelected: (idRemetente) {
                  if (idRemetente.isEmpty) {
                    provider.restaurarLista();
                  } else {
                    provider.filtrarPorRemetente(idRemetente);
                  }
                },
                itemBuilder: (_) {
                  final remetentes = provider.remetentesUnicos;
                  return [
                    const PopupMenuItem(
                      value: '',
                      child: Text('Todos os remetentes'),
                    ),
                    ...remetentes.map(
                      (r) => PopupMenuItem(
                        value: r['id']!,
                        child: Text(r['nome'] ?? 'Remetente desconhecido'),
                      ),
                    ),
                  ];
                },
              )
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.notificacoes.isEmpty
                  ? _telaVaziaCentralizada(context)
                  : ListView.builder(
                      itemCount: provider.notificacoes.length,
                      itemBuilder: (context, index) {
                        final notif = provider.notificacoes[index];
                        final dataFormatada = DateFormat('dd/MM/yyyy HH:mm')
                            .format(notif.criadoEm.toLocal());

                        final isNaoLida = notif.lidoEm == null;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isNaoLida
                                  ? primary.withOpacity(0.06)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              onTap: () {
                                // Marca como lida, se aplicável
                                if (notif.lidoEm == null) {
                                  provider.marcarComoLida(notif.id);
                                }

                                // Verifica se é notificação de amizade
                                if (notif.tipo.toLowerCase() == 'amizade' ||
                                    notif.tipo.toLowerCase() == 'envio convite' ||
                                    notif.tipo.toLowerCase() == 'aceite convite') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExplorarCervejeirosScreen(
                                        onVoltar: () {
                                          navigatorKey.currentState
                                              ?.pushReplacementNamed('/notificacoes');
                                        },
                                      ),
                                    ),
                                  );
                                }

                                // Continua tratando outros tipos (ex: cadastro cerveja)
                                else if (notif.tipo.toLowerCase() == 'cadastro cerveja') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TelaCervejasAmigos(
                                        idCervejeiro: notif.idRemetente,
                                        origem: "notificacoes",
                                      ),
                                    ),
                                  );
                                }
                              },
                              title: Text(
                                notif.mensagem,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isNaoLida ? Colors.black : Colors.grey[800],
                                ),
                              ),
                              subtitle: Text(
                                dataFormatada,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isNaoLida ? Colors.blueGrey : Colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.mark_email_read,
                                      size: 20,
                                      color: isNaoLida ? primary : Colors.grey,
                                    ),
                                    onPressed: isNaoLida
                                        ? () => provider.marcarComoLida(notif.id)
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () =>
                                        provider.excluirNotificacao(notif.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
