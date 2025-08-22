import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notificacao_provider.dart';
import '../models/notificacao.dart';

class TelaNotificacoes extends StatefulWidget {
  final String idUsuarioLogado;
  final VoidCallback? onVoltar;

  const TelaNotificacoes({
    required this.idUsuarioLogado,
    this.onVoltar,
    super.key,
  });

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  List<NotificacaoModel> _backup = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificacaoProvider>();
      provider.carregarNotificacoes(widget.idUsuarioLogado).then((_) {
        setState(() {
          _backup = provider.notificacoes;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacaoProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificações'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => widget.onVoltar?.call(),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (tipo) {
                  if (tipo == 'Todos') {
                    provider.restaurarLista(_backup);
                  } else {
                    provider.filtrarPorTipo(tipo);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Todos', child: Text('Todos')),
                  PopupMenuItem(value: 'amizade', child: Text('Amizade')),
                  PopupMenuItem(value: 'cerveja', child: Text('Cerveja')),
                  PopupMenuItem(value: 'evento', child: Text('Evento')),
                ],
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.notificacoes.isEmpty
                  ? const Center(child: Text('Nenhuma notificação encontrada.'))
                  : ListView.builder(
                      itemCount: provider.notificacoes.length,
                      itemBuilder: (context, index) {
                        final notif = provider.notificacoes[index];
                        final dataFormatada = DateFormat('dd/MM/yyyy HH:mm')
                            .format(notif.criadoEm.toLocal());

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(
                              dataFormatada,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              notif.mensagem,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (notif.lidoEm == null)
                                  IconButton(
                                    icon: const Icon(Icons.mark_email_read,
                                        size: 20),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      provider.marcarComoLida(notif.id);
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    provider.excluirNotificacao(notif.id);
                                  },
                                ),
                              ],
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
