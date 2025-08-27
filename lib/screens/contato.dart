import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaContato extends StatefulWidget {
  const TelaContato({Key? key}) : super(key: key);

  @override
  State<TelaContato> createState() => _TelaContatoState();
}

class _TelaContatoState extends State<TelaContato> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubject;
  String _message = '';
  bool _isSending = false;

  // 🔹 Controller para limpar o campo mensagem
  final TextEditingController _messageController = TextEditingController();

  final List<String> _subjects = [
    'Sugestão',
    'Reclamação',
    'Outros',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensagem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado.')),
        );
        return;
      }

      final insertData = {
        'remetente_id': user.id,
        'assunto': _selectedSubject,
        'mensagem': _message,
      };

      debugPrint('Enviando para Supabase: $insertData');
      debugPrint(Supabase.instance.client.auth.currentUser?.id);

      await Supabase.instance.client
          .from('mensagens_contato')
          .insert(insertData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem enviada com sucesso!')),
      );

      // 🔹 Limpa o dropdown e o campo de mensagem
      setState(() {
        _selectedSubject = null;
        _message = '';
        _messageController.clear();
      });
    } catch (e, stack) {
      debugPrint('Erro ao enviar mensagem: $e');
      debugPrintStack(stackTrace: stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fale com a gente'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🖼 Imagem no topo
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Image.asset(
                    'assets/contato.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Queremos ouvir você!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Envie sua mensagem para sugestões, reclamações ou outros assuntos. Sua opinião é muito importante para nós.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ComboBox Assunto
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Assunto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedSubject,
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecione um assunto' : null,
                ),
                const SizedBox(height: 16),

                // Campo de mensagem com controller
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Mensagem',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _message = value,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Digite sua mensagem'
                          : null,
                ),
                const SizedBox(height: 24),

                // Botão Enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _enviarMensagem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(_isSending ? 'Enviando...' : 'Enviar Mensagem'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
