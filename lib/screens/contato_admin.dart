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
        .select()
        .order('created_at', ascending: false);

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
                content: Text('Nova mensagem de ${nova['nome']}'),
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
        title: Text('Responder ${mensagem['nome']}'),
        content: TextField(
          controller: respostaController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Digite sua resposta...',
            border: OutlineInputBorder(),
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
              if (resposta.isNotEmpty) {
                await supabase
                    .from('mensagens_contato')
                    .update({
                      'resposta': resposta,
                      'respondido_em': DateTime.now().toIso8601String(),
                    })
                    .eq('id', mensagem['id']);

                Navigator.pop(ctx);
                _carregarMensagens();
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens de Contato'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : mensagens.isEmpty
              ? const Center(child: Text('Nenhuma mensagem recebida.'))
              : ListView.builder(
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index];
                    final dataEnvio = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(msg['created_at']));

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(msg['assunto'] ?? 'Sem assunto'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg['mensagem'] ?? ''),
                            const SizedBox(height: 4),
                            Text('De: ${msg['nome']} - ${msg['email']}'),
                            Text('Enviado em: $dataEnvio'),
                            if (msg['resposta'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  'Resposta: ${msg['resposta']}',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.green),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.reply, color: Colors.blue),
                          onPressed: () => _responderMensagem(msg),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
