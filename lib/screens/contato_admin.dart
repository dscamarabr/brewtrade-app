import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaContatoAdmin extends StatefulWidget {
  const TelaContatoAdmin({Key? key}) : super(key: key);

  @override
  State<TelaContatoAdmin> createState() => _TelaContatoAdminState();
}

class _TelaContatoAdminState extends State<TelaContatoAdmin> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> mensagens = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMensagens();
    _escutarNovasMensagens();
  }

  Future<void> _carregarMensagens() async {
    final response = await supabase
        .from('mensagens_contato')
        .select('id, mensagem, assunto, criado_em, respondido_em, remetente_id, status, tb_cervejeiro(nome)')
        .order('criado_em', ascending: false);

    setState(() {
      mensagens = List<Map<String, dynamic>>.from(response);
      carregando = false;
    });
  }

  void _escutarNovasMensagens() {
    supabase
        .channel('mensagens_contato')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensagens_contato',
          callback: (payload) {
            final nova = Map<String, dynamic>.from(payload.newRecord);
            setState(() {
              mensagens.insert(0, nova);
            });

            // Notificação visual no app
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nova mensagem recebida'),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        )
        .subscribe();
  }

  void _responderMensagem(Map<String, dynamic> mensagem) {
    final respostaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Responder ${mensagem['tb_cervejeiro']?['nome'] ?? 'Cervejeiro'}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 250,
          child: TextField(
            controller: respostaController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Digite sua resposta...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final resposta = respostaController.text.trim();
              if (resposta.isEmpty) return;

              final userId = supabase.auth.currentUser?.id;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro: usuário não autenticado')),
                );
                return;
              }

              // 1) Atualiza a mensagem de contato: status + respondido_em
              await supabase
                  .from('mensagens_contato')
                  .update({
                    'status': 'respondida',
                    'respondido_em': DateTime.now().toIso8601String(),
                  })
                  .eq('id', mensagem['id']);

              // 2) Insere notificação para o remetente, com a resposta no mensagem_push
              await supabase.from('tb_notificacoes').insert({
                'id_usuario_remetente': userId,
                'id_usuario_destinatario': mensagem['remetente_id'],
                'tp_notificacao': 'Resposta Admin',
                'criado_em': DateTime.now().toIso8601String(),
                'lido_em': null,
                'mensagem_push': resposta,
              });

              Navigator.pop(ctx);
              _carregarMensagens();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separa mensagens por status
    final novas = mensagens
        .where((m) => (m['status'] ?? '').toString().toLowerCase() == 'nova')
        .toList()
      ..sort((a, b) => DateTime.parse(b['criado_em'])
          .compareTo(DateTime.parse(a['criado_em'])));

    final respondidas = mensagens
        .where((m) => (m['status'] ?? '').toString().toLowerCase() == 'respondida')
        .toList()
      ..sort((a, b) => DateTime.parse(b['respondido_em'])
          .compareTo(DateTime.parse(a['respondido_em'])));

    Widget buildCard(Map<String, dynamic> msg) {
      final nome = msg['tb_cervejeiro']?['nome'] ?? 'Desconhecido';
      final dataEnvio = DateFormat('dd/MM/yyyy HH:mm')
          .format(DateTime.parse(msg['criado_em']));

      return GestureDetector(
        onTap: () => _responderMensagem(msg),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('De: $nome',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Enviado em: $dataEnvio'),
                const SizedBox(height: 4),
                Text(
                  'Tipo de Mensagem: ${msg['assunto'] ?? 'Sem assunto'}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text('Mensagem:',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(msg['mensagem'] ?? ''),
                if (msg['respondido_em'] != null) ...[
                  const SizedBox(height: 12),
                  Text('Respondido em:',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.green)),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(msg['respondido_em'])),
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.green),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens de Contato')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : mensagens.isEmpty
              ? const Center(child: Text('Nenhuma mensagem recebida.'))
              : ListView(
                  children: [
                    if (novas.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        color: Colors.orange.withOpacity(0.15),
                        padding: const EdgeInsets.all(12),
                        child: const Text(
                          'Novas',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                      ),
                      ...novas.map(buildCard),
                    ],
                    if (respondidas.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        color: Colors.green.withOpacity(0.15),
                        padding: const EdgeInsets.all(12),
                        child: const Text(
                          'Respondidas',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                      ...respondidas.map(buildCard),
                    ],
                  ],
                ),
    );
  }

}
