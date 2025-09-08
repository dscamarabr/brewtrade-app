import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '/models/cerveja.dart';
import 'package:provider/provider.dart';
import '../services/cerveja_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'tela_base.dart';


class TelaCadastroCerveja extends StatefulWidget {
  final Cerveja? cerveja;
  final void Function()? onSalvar;
  final void Function()? onVoltar;
  final bool popAoSalvar;

  const TelaCadastroCerveja({
    this.cerveja,
    this.onSalvar,
    this.onVoltar,
    this.popAoSalvar = false,
    Key? key,
  }) : super(key: key);

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

    if (isEditando) {
      await Supabase.instance.client
          .from('tb_cervejas')
          .update(dados)
          .eq('id_cerveja', widget.cerveja!.id_cerveja);
    } else {
      await Supabase.instance.client
          .from('tb_cervejas')
          .insert(dados)
          .select()
          .single();
    }

    Provider.of<CervejaProvider>(context, listen: false).carregarCervejasDoBanco();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sucesso! 🍺'),
        content: Text('Cerveja ${isEditando ? 'atualizada' : 'cadastrada'} com sucesso.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onVoltar?.call();
              if (widget.popAoSalvar) {
                Navigator.of(context).pop();
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
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

  return TelaBase(
    onVoltar: () {
      widget.onVoltar?.call();
      if (Navigator.canPop(context)) Navigator.pop(context);
    },
    child: Scaffold(
        appBar: AppBar(
          title: Text(isEditando ? 'Editar Cerveja' : 'Cadastrar Cerveja'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onVoltar?.call();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: nomeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: const Icon(Icons.local_drink),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                  onChanged: (value) {
                    final capitalizado = value
                        .split(' ')
                        .map((word) => word.isNotEmpty
                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                            : '')
                        .join(' ');
                    if (value != capitalizado) {
                      nomeCtrl.value = nomeCtrl.value.copyWith(
                        text: capitalizado,
                        selection: TextSelection.collapsed(offset: capitalizado.length),
                      );
                    }
                  },                  
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cervejariaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cervejaria',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/cervejaria.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Informe a cervejaria' : null,
                  onChanged: (value) {
                    final capitalizado = value
                        .split(' ')
                        .map((word) => word.isNotEmpty
                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                            : '')
                        .join(' ');
                    if (value != capitalizado) {
                      cervejariaCtrl.value = cervejariaCtrl.value.copyWith(
                        text: capitalizado,
                        selection: TextSelection.collapsed(offset: capitalizado.length),
                      );
                    }
                  },                  
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: estiloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Estilo',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/estilo_cerveja.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Informe o estilo' : null,
                  onChanged: (value) {
                    final capitalizado = value
                        .split(' ')
                        .map((word) => word.isNotEmpty
                            ? '${word[0].toUpperCase()}${word.substring(1)}'
                            : '')
                        .join(' ');
                    if (value != capitalizado) {
                      estiloCtrl.value = estiloCtrl.value.copyWith(
                        text: capitalizado,
                        selection: TextSelection.collapsed(offset: capitalizado.length),
                      );
                    }
                  },                  
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: abvCtrl,
                  decoration: InputDecoration(
                    labelText: 'ABV (%)',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/abv.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o ABV';
                    final abv = double.tryParse(v);
                    return abv == null || abv < 0 ? 'ABV inválido' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ibuCtrl,
                  decoration: InputDecoration(
                    labelText: 'IBU',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/lupulo.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final ibu = int.tryParse(v);
                      if (ibu == null || ibu < 0) return 'IBU inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: volumeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Volume (ml)',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/garrafa_cerveja.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o volume';
                    final vol = int.tryParse(v);
                    return vol == null || vol <= 0 ? 'Volume inválido' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantidadeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/quantidade_cervejas.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final qtd = int.tryParse(v);
                      if (qtd == null || qtd < 0) return 'Quantidade inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descricaoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: const Icon(Icons.notes),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final capitalizado = value[0].toUpperCase() + value.substring(1);
                      if (value != capitalizado) {
                        descricaoCtrl.value = descricaoCtrl.value.copyWith(
                          text: capitalizado,
                          selection: TextSelection.collapsed(offset: capitalizado.length),
                        );
                      }
                    }
                  },                  
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecionar imagens (máx 3):',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Escolher imagens'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final imgs = await picker.pickMultiImage();
                    if ((imagensExistentes.length + imgs.length) <= 3) {
                      setState(() => imagensSelecionadas = imgs);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Máximo de 3 imagens por cerveja')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: [
                    ...imagensExistentes.map((url) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    confirmarExclusaoImagemExistente(url),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      Colors.black.withOpacity(0.7),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ...imagensSelecionadas.map((imagem) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(imagem.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    confirmarExclusaoImagemSelecionada(imagem),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      Colors.black.withOpacity(0.7),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: situacao,
                  decoration: InputDecoration(
                    labelText: 'Situação',
                    prefixIcon: Icon(
                      situacao == 'Disponível para troca'
                          ? Icons.swap_horiz
                          : Icons.pause_circle,
                      color: situacao == 'Disponível para troca'
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),                    
                  ),
                  items: ['Disponível para troca', 'Inativa']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => situacao = value!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Cerveja'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: salvarCerveja,
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
