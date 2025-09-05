import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/perfil_provider.dart';
import '../services/tema_provider.dart';

class PerfilScreen extends StatefulWidget {
  final void Function()? onVoltar;

  const PerfilScreen({super.key, this.onVoltar});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final cidadeController = TextEditingController();
  final cervejariaController = TextEditingController();
  final bioController = TextEditingController();
  final redeSocialController = TextEditingController();

  String? estadoSelecionado;
  bool loading = false;

  final estadosValidos = [
    'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB',
    'PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final perfilProvider = context.watch<PerfilProvider>();

    nomeController.text = perfilProvider.nome ?? '';
    telefoneController.text = perfilProvider.telefone ?? '';
    estadoSelecionado = perfilProvider.estado;
    cidadeController.text = perfilProvider.cidade ?? '';
    cervejariaController.text = perfilProvider.cervejaria ?? '';
    bioController.text = perfilProvider.bio ?? '';
    redeSocialController.text = perfilProvider.redeSocial ?? '';
  }

  String? validarTelefone(String? value) {
    final regex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
    if (value == null || value.isEmpty) return 'Informe o telefone';
    if (!regex.hasMatch(value)) return 'Formato inválido. Ex: (11) 91234-5678';
    return null;
  }

  String? validarEstado(String? value) {
    if (value == null || value.isEmpty) return 'Selecione o estado';
    if (!estadosValidos.contains(value.toUpperCase())) return 'Estado inválido';
    return null;
  }

  Future<String?> _selecionarImagem() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final fileExt = p.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'foto_${userId}_$timestamp$fileExt';

    try {
      await Supabase.instance.client.storage
          .from('perfil-fotos')
          .upload(fileName, File(file.path), fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('perfil-fotos')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _salvarOuEditarPerfil() async {
    final perfilProvider = context.read<PerfilProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final data = {
      'id': user.id,
      'nome': nomeController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'estado': estadoSelecionado?.toUpperCase(),
      'cidade': cidadeController.text.trim(),
      'cervejaria': cervejariaController.text.trim(),
      'fotoUrl': perfilProvider.fotoUrl?.trim(),
      'permite_notificacoes': perfilProvider.permiteNotificacoes,
      'visivel_pesquisa': perfilProvider.visivelPesquisa,
      'bio': bioController.text.trim(),
      'rede_social': redeSocialController.text.trim(),
    };

    try {
      // 🔍 Verifica se já existe perfil com esse ID no Supabase
      final existePerfil = await Supabase.instance.client
          .from('tb_cervejeiro')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existePerfil != null) {
        await Supabase.instance.client
            .from('tb_cervejeiro')
            .update(data)
            .eq('id', user.id);
      } else {
        data['criadoEm'] = DateTime.now().toIso8601String();
        await Supabase.instance.client
            .from('tb_cervejeiro')
            .insert(data);
      }

      // 🔄 Atualiza localmente no provider
      perfilProvider.atualizarPerfil(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil salvo com sucesso!'),
          backgroundColor: Colors.blue.shade600, 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilProvider = context.watch<PerfilProvider>();
    final temaProvider = context.watch<TemaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Cervejeiro 🍻'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onVoltar?.call();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe seu nome' : null,
                onChanged: (value) {
                  final capitalizado = value
                      .split(' ')
                      .map((word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '')
                      .join(' ');
                  if (value != capitalizado) {
                    nomeController.value = nomeController.value.copyWith(
                      text: capitalizado,
                      selection: TextSelection.collapsed(offset: capitalizado.length),
                    );
                  }
                },
              ),
              TextFormField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Celular'),
                keyboardType: TextInputType.phone,
                inputFormatters: [MaskedInputFormatter('(00) 00000-0000')],
                validator: validarTelefone,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Estado'),
                value: estadoSelecionado,
                items: estadosValidos
                    .map((sigla) =>
                        DropdownMenuItem(value: sigla, child: Text(sigla)))
                    .toList(),
                onChanged: (value) => setState(() {
                  estadoSelecionado = value;
                }),
                validator: validarEstado,
              ),
              TextFormField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  final capitalizado = value
                      .split(' ')
                      .map((word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '')
                      .join(' ');
                  if (value != capitalizado) {
                    cidadeController.value = cidadeController.value.copyWith(
                      text: capitalizado,
                      selection: TextSelection.collapsed(offset: capitalizado.length),
                    );
                  }
                },
              ),
              TextFormField(
                controller: cervejariaController,
                decoration: const InputDecoration(labelText: 'Cervejaria'),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  final capitalizado = value
                      .split(' ')
                      .map((word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '')
                      .join(' ');
                  if (value != capitalizado) {
                    cervejariaController.value = cervejariaController.value.copyWith(
                      text: capitalizado,
                      selection: TextSelection.collapsed(offset: capitalizado.length),
                    );
                  }
                },
              ),
              TextFormField(
                controller: redeSocialController,
                decoration: InputDecoration(labelText: 'Perfil Instagram'),
              ),
              TextFormField(
                controller: bioController,
                decoration: InputDecoration(labelText: 'Bio'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                  final capitalizado = value[0].toUpperCase() + value.substring(1);
                  if (value != capitalizado) {
                    bioController.value = bioController.value.copyWith(
                    text: capitalizado,
                    selection: TextSelection.collapsed(offset: capitalizado.length),
                    );
                  }
                  }
                },
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Foto de Perfil',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12), // leve arredondamento
                              image: DecorationImage(
                                image: perfilProvider.fotoUrl?.isNotEmpty == true
                                    ? NetworkImage(perfilProvider.fotoUrl!)
                                    : const AssetImage('assets/imagem_padrao.png') as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (perfilProvider.fotoUrl?.isNotEmpty == true)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => perfilProvider.removerFoto(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          final url = await _selecionarImagem();
                          if (url != null) {
                            perfilProvider.atualizarFoto(url);
                            final userId = Supabase.instance.client.auth.currentUser?.id;
                            if (userId != null) {
                              await Supabase.instance.client
                                  .from('tb_cervejeiro')
                                  .update({'fotoUrl': url})
                                  .eq('id', userId);
                            }
                          }
                        },
                        icon: const Icon(Icons.photo),
                        label: const Text('Selecionar imagem'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
/*               Center(
                child: Column(
                  children: [
                    const Text(
                      'Escolha o Tema do App',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'pilsen',
                          label: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wb_sunny, size: 20, color: Colors.orange),
                                SizedBox(width: 6),
                                Text('PILSEN'),
                              ],
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'ipa',
                          label: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_drink, size: 20, color: Colors.deepOrange),
                                SizedBox(width: 6),
                                Text('IPA'),
                              ],
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'stout',
                          label: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.nightlife, size: 20, color: Colors.brown),
                                SizedBox(width: 6),
                                Text('STOUT'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      selected: {temaProvider.temaNome},
                      onSelectionChanged: (Set<String> selecionado) {
                        temaProvider.aplicarTemaPorNome(selecionado.first);
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 12),
                        ),
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          return states.contains(MaterialState.selected)
                              ? Colors.amber.shade200
                              : Colors.grey.shade300;
                        }),
                        foregroundColor: MaterialStateProperty.all(Colors.brown.shade900),
                        textStyle: MaterialStateProperty.all(
                          TextStyle(fontWeight: FontWeight.w600),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ), */
              const SizedBox(height: 24),              
              CheckboxListTile(
                title: const Text('Receber notificações'),
                value: perfilProvider.permiteNotificacoes,
                onChanged: (value) {
                  perfilProvider.atualizarPerfil({
                    'permite_notificacoes': value ?? true,
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Mostrar meu perfil na pesquisa'),
                value: perfilProvider.visivelPesquisa,
                onChanged: (value) {
                  perfilProvider.atualizarPerfil({
                    'visivel_pesquisa': value ?? true,
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton.icon(
          onPressed: loading ? null : _salvarOuEditarPerfil,
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_alt),
          label: Text(
            loading ? 'Salvando...' : 'Salvar Perfil',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),      
    );
  }
}


