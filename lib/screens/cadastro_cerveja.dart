import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '/models/cerveja.dart';
import 'package:provider/provider.dart';
import '../services/cerveja_provider.dart';
import 'package:flutter/services.dart';


class TelaCadastroCerveja extends StatefulWidget {
  final Cerveja? cerveja;
  final void Function()? onSalvar;
  final void Function()? onVoltar;
  final bool popAoSalvar;

  const TelaCadastroCerveja({this.cerveja,
                             this.onSalvar,
                             this.onVoltar,
                             this.popAoSalvar = false,
                             Key? key})
      : super(key: key);

  @override
  State<TelaCadastroCerveja> createState() => _TelaCadastroCervejaState();
}

class _TelaCadastroCervejaState extends State<TelaCadastroCerveja> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nomeCtrl = TextEditingController();
  final cervejariaCtrl = TextEditingController();
  final estiloCtrl = TextEditingController();
  final abvCtrl = TextEditingController();
  final ibuCtrl = TextEditingController();
  final volumeCtrl = TextEditingController();
  final quantidadeCtrl = TextEditingController();
  final descricaoCtrl = TextEditingController();

  String situacao = 'Disponível para troca';
  List<XFile> imagensSelecionadas = [];
  List<String> imagensExistentes = [];
  late final bool isEditando;

  @override
  void initState() {
    super.initState();
    isEditando = widget.cerveja != null;

    if (isEditando) {
      preencherCampos(widget.cerveja!);
    } else {
      limparCampos();
    }
  }

  @override
  void didUpdateWidget(covariant TelaCadastroCerveja oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.cerveja == null && oldWidget.cerveja != null) {
      limparCampos();
    } else if (widget.cerveja != null && widget.cerveja != oldWidget.cerveja) {
      preencherCampos(widget.cerveja!);
    }

    setState(() {});
  }

  void preencherCampos(Cerveja c) {
    nomeCtrl.text = c.nome;
    cervejariaCtrl.text = c.cervejaria;
    estiloCtrl.text = c.estilo;
    abvCtrl.text = c.abv.toString();
    ibuCtrl.text = c.ibu?.toString() ?? '';
    volumeCtrl.text = c.volume.toString();
    quantidadeCtrl.text = c.quantidade?.toString() ?? '';
    descricaoCtrl.text = c.descricao ?? '';
    situacao = c.situacao;
    imagensExistentes = c.imagens ?? [];
  }

  void limparCampos() {
    nomeCtrl.clear();
    cervejariaCtrl.clear();
    estiloCtrl.clear();
    abvCtrl.clear();
    ibuCtrl.clear();
    volumeCtrl.clear();
    quantidadeCtrl.clear();
    descricaoCtrl.clear();
    situacao = 'Disponível para troca';
    imagensSelecionadas.clear();
    imagensExistentes.clear();
    buscarCervejariaDoUsuario();
  }

  Future<void> buscarCervejariaDoUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final res = await Supabase.instance.client
          .from('tb_cervejeiro')
          .select('cervejaria')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      
      setState(() {
        cervejariaCtrl.text = res['cervejaria'] ?? '';
      });
    }
  }

  String extrairNomeArquivo(String url) => url.split('/').last;

  Future<List<String>> uploadImagens() async {
    final storage = Supabase.instance.client.storage.from('cervejas');
    List<String> urls = [];
    for (final img in imagensSelecionadas) {
      final bytes = await img.readAsBytes();
      final nomeArquivo = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await storage.uploadBinary(nomeArquivo, bytes);
      urls.add(storage.getPublicUrl(nomeArquivo));
    }
    return urls;
  }

  void confirmarExclusaoImagemExistente(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover imagem'),
        content: Text('Deseja remover esta imagem permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => imagensExistentes.remove(url));
              await Supabase.instance.client.storage
                  .from('cervejas')
                  .remove([extrairNomeArquivo(url)]);
            },
            child: Text('Remover'),
          ),
        ],
      ),
    );
  }

  void confirmarExclusaoImagemSelecionada(XFile img) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover imagem'),
        content: Text('Deseja remover esta imagem selecionada?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => imagensSelecionadas.remove(img));
            },
            child: Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tem certeza?'),
        content: const Text('As alterações não foram salvas. Deseja sair assim mesmo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    return sair ?? false;
  }  

  Future<void> salvarCerveja() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    final novasImagens = await uploadImagens();
    final todasImagens = [...imagensExistentes, ...novasImagens].take(3).toList();

    final dados = {
      'nome': nomeCtrl.text,
      'cervejaria': cervejariaCtrl.text,
      'estilo': estiloCtrl.text,
      'abv': double.parse(abvCtrl.text),
      'ibu': int.tryParse(ibuCtrl.text),
      'volume': int.parse(volumeCtrl.text),
      'quantidade': int.tryParse(quantidadeCtrl.text),
      'descricao': descricaoCtrl.text,
      'situacao': situacao,
      'imagens': todasImagens,
      'id_usuario': userId,
      'data_cadastro': DateTime.now().toIso8601String(),
    };

    if (widget.cerveja != null) {
      await Supabase.instance.client
          .from('tb_cervejas')
          .update(dados)
          .eq('id_cerveja', widget.cerveja!.id_cerveja);

      Provider.of<CervejaProvider>(context, listen: false).carregarCervejasDoBanco();
    } else {
      await Supabase.instance.client
          .from('tb_cervejas')
          .insert(dados)
          .select()
          .single();

      Provider.of<CervejaProvider>(context, listen: false).carregarCervejasDoBanco();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sucesso! 🍺'),
        content: Text('Cerveja ${isEditando ? 'atualizada' : 'cadastrada'} com sucesso.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();       // fecha o diálogo
              widget.onVoltar?.call();       // executa lógica de retorno ao menu

              if (widget.popAoSalvar) {
                Navigator.of(context).pop(); // fecha a tela só se ela veio via push
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final sair = await _confirmarSaida();
        if (sair) {
          widget.onVoltar?.call(); // se precisar atualizar lista, etc.
        }
        return sair; // permite o pop quando confirmado
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditando ? 'Editar Cerveja' : 'Cadastrar Cerveja'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final sair = await _confirmarSaida();
              if (sair) {
                widget.onVoltar?.call();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(controller: nomeCtrl, decoration: InputDecoration(labelText: 'Nome'), validator: (v) => v!.isEmpty ? 'Informe o nome' : null),
                TextFormField(controller: cervejariaCtrl, decoration: InputDecoration(labelText: 'Cervejaria'), validator: (v) => v!.isEmpty ? 'Informe a cervejaria' : null),
                TextFormField(controller: estiloCtrl, decoration: InputDecoration(labelText: 'Estilo'), validator: (v) => v!.isEmpty ? 'Informe o estilo' : null),
                TextFormField(controller: abvCtrl, decoration: InputDecoration(labelText: 'ABV (%)'), keyboardType: TextInputType.number, inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),], validator: (v) { if (v == null || v.isEmpty) return 'Informe o ABV'; final abv = double.tryParse(v); return abv == null || abv < 0 ? 'ABV inválido' : null;  },),
                TextFormField(controller: ibuCtrl, decoration: InputDecoration(labelText: 'IBU'), keyboardType: TextInputType.number, inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),], validator: (v) { if (v != null && v.isNotEmpty) { final ibu = int.tryParse(v); if (ibu == null || ibu < 0) return 'IBU inválido'; } return null; },),
                TextFormField(controller: volumeCtrl, decoration: InputDecoration(labelText: 'Volume (ml)'), keyboardType: TextInputType.number, inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),], validator: (v) { if (v == null || v.isEmpty) return 'Informe o volume'; final vol = int.tryParse(v); return vol == null || vol <= 0 ? 'Volume inválido' : null; },),
                TextFormField(controller: quantidadeCtrl, decoration: InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number, inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),], validator: (v) { if (v != null && v.isNotEmpty) { final qtd = int.tryParse(v); if (qtd == null || qtd < 0) return 'Quantidade inválida'; } return null; },),
                TextFormField(controller: descricaoCtrl, decoration: InputDecoration(labelText: 'Descrição'), maxLines: 3),
                DropdownButtonFormField<String>(
                  value: situacao,
                  decoration: InputDecoration(labelText: 'Situação'),
                  items: ['Disponível para troca','Inativa']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => situacao = value!),
                ),
                SizedBox(height: 20),
                Text('Selecionar imagens (máx 3):'),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final imgs = await picker.pickMultiImage();
                    if ((imagensExistentes.length + imgs.length) <= 3) {
                      setState(() => imagensSelecionadas = imgs);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cada cerveja pode ter no máximo 3 imagens')),
                      );
                    }
                  },
                  child: Text('Escolher imagens'),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...imagensExistentes.map((url) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => confirmarExclusaoImagemExistente(url),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black.withOpacity(0.7),
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ...imagensSelecionadas.map((imagem) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(imagem.path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => confirmarExclusaoImagemSelecionada(imagem),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black.withOpacity(0.7),
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: salvarCerveja,
                  child: Text(isEditando ? 'Atualizar' : 'Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

