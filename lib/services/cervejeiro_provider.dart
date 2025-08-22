import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cervejeiro {
  final String id;
  final String nome;
  final String estado;
  final String? cidade;
  final String telefone;
  final String? cervejaria;
  final String? fotoUrl;
  final String? bio;
  final String? redeSocial;
  final bool visivelPesquisa;

  Cervejeiro({
    required this.id,
    required this.nome,
    required this.estado,
    this.cidade,
    required this.telefone,
    this.cervejaria,
    this.fotoUrl,
    this.bio,
    this.redeSocial,
    required this.visivelPesquisa,
  });

  factory Cervejeiro.fromMap(Map<String, dynamic> map) {
    return Cervejeiro(
      id: map['id'] as String,
      nome: map['nome'] ?? '',
      estado: map['estado'] ?? '',
      cidade: map['cidade'], 
      telefone: map['telefone'], 
      cervejaria: map['cervejaria'], 
      fotoUrl: map['fotoUrl'], 
      bio: map['bio'],
      redeSocial: map['rede_social'],
      visivelPesquisa: map['visivel_pesquisa'] ?? false,
    );
  }
}

class CervejeiroProvider extends ChangeNotifier {
  final List<Cervejeiro> _todos = [];
  String _estadoSelecionado = '';
  List<Cervejeiro> _cervejeiros = [];
  List<Cervejeiro> get cervejeiros => _cervejeiros;  
  List<Map<String, dynamic>> _amizades = [];

  List<Cervejeiro> get cervejeirosVisiveis {
    final String meuId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final filtrados = _todos.where((c) =>
      c.visivelPesquisa &&
      c.id != meuId &&
      (_estadoSelecionado.isEmpty || c.estado == _estadoSelecionado)
    ).toList();

    filtrados.sort((a, b) => a.nome.compareTo(b.nome)); // A-Z
    return filtrados;
  }

  List<String> get estadosDisponiveis {
    return _cervejeiros.map((c) => c.estado).toSet().toList()..sort();
  }

  int statusOrdenacao(String idCervejeiro) {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;

    if (usuarioAtual == null) return 0;

    final amizade = _amizades.firstWhere(
      (a) => Set.from([a['id_cervejeiro_a'], a['id_cervejeiro_b']])
                  .containsAll([usuarioAtual, idCervejeiro]),
      orElse: () => <String, dynamic>{},
    );

    if (amizade.isEmpty) return 0; // sem vínculo

    final iniciadoPorUsuario = amizade['id_cervejeiro_a'] == usuarioAtual;
    final status = amizade['status'];

    if (status == 'recusado') return 4;

    if (iniciadoPorUsuario) {
      if (status == 'pendente') return 1;
      if (status == 'aceito') return 2;
    } else {
      if (status == 'aceito') return 3; // aceito mas iniciado por outro
    }

    return 0;
  }

  String statusAmizade(String idCervejeiro) {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return '';

    final amizade = _amizades.firstWhere(
      (a) => (a['id_cervejeiro_a'] == usuarioAtual && a['id_cervejeiro_b'] == idCervejeiro) ||
            (a['id_cervejeiro_b'] == usuarioAtual && a['id_cervejeiro_a'] == idCervejeiro),
      orElse: () => <String, dynamic>{},
    );

    // Só considera como vínculo relevante se o atual usuário foi quem iniciou
    final iniciadoPorUsuario = amizade['id_cervejeiro_a'] == usuarioAtual;

    if (amizade.isEmpty) return ''; // sem vínculo
    if (!iniciadoPorUsuario && amizade['status'] != 'aceito') return ''; // vínculo iniciado por outro, ainda não aceito

    return amizade['status'] ?? '';
  }

  String get estadoSelecionado => _estadoSelecionado;

  void aplicarFiltroEstado(String estado) {
    _estadoSelecionado = estado;
    notifyListeners();
  }

  Future<void> carregarAmizades() async {
    try {
      final response = await Supabase.instance.client
          .from('amizades')
          .select();

      _amizades = response.whereType<Map<String, dynamic>>().toList();

      if (_amizades.isEmpty) {
        print('Nenhuma amizade encontrada ou resposta inesperada.');
      }
    } catch (e) {
      _amizades = [];
      print('Erro ao carregar amizades: $e');
    }
  }

  List<Cervejeiro> get cervejeirosOrdenados {
    final lista = [..._cervejeiros];
    lista.sort((a, b) =>
      statusOrdenacao(a.id).compareTo(statusOrdenacao(b.id)));
    return lista;
  }

  Future<void> removerAmizade(String cervejeiroId, BuildContext context) async {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return;

    await Supabase.instance.client
      .from('amizades')
      .delete()
      .or(
        'and(id_cervejeiro_a.eq.$usuarioAtual,id_cervejeiro_b.eq.$cervejeiroId),'
        'and(id_cervejeiro_a.eq.$cervejeiroId,id_cervejeiro_b.eq.$usuarioAtual)'
      );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Amizade ou solicitação removida com sucesso.'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> atualizarCervejeiros() async {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return;

    // 🔄 Busca todos os cervejeiros exceto o atual
    final response = await Supabase.instance.client
      .from('tb_cervejeiro')
      .select()
      .neq('id', usuarioAtual);

    final listaAtualizada = (response as List).map((e) => Cervejeiro.fromMap(e)).toList();

    // 🔍 Busca amizades do usuário atual
    final amizadesResponse = await Supabase.instance.client
      .from('amizades')
      .select()
      .or('id_cervejeiro_a.eq.$usuarioAtual,id_cervejeiro_b.eq.$usuarioAtual');

    final listaAmizades = amizadesResponse as List;

    _amizades = listaAmizades.whereType<Map<String, dynamic>>().toList();

    // Cria um mapa com status da amizade por cervejeiroId
    final Map<String, String> mapaStatus = {};
    for (final item in listaAmizades) {
      final idA = item['id_cervejeiro_a'];
      final idB = item['id_cervejeiro_b'];
      final idOutro = (idA == usuarioAtual) ? idB : idA;
      mapaStatus[idOutro] = item['status'];
    }

    // Armazena tudo
    _cervejeiros = listaAtualizada;

    notifyListeners(); // Atualiza a UI
  }

  Future<Map<String, dynamic>?> buscarAmizade(String cervejeiroId) async {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return null;

    final response = await Supabase.instance.client
      .from('amizades')
      .select()
      .or('and(id_cervejeiro_a.eq.$usuarioAtual,id_cervejeiro_b.eq.$cervejeiroId),and(id_cervejeiro_a.eq.$cervejeiroId,id_cervejeiro_b.eq.$usuarioAtual)')
      .maybeSingle();

    return response;
  }

  Future<void> enviarConviteAmizade(String cervejeiroId, BuildContext context) async {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return;

    try {
      await Supabase.instance.client.from('amizades').insert({
        'id_cervejeiro_a': usuarioAtual,
        'id_cervejeiro_b': cervejeiroId,
        'status': 'pendente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Convite enviado com sucesso!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar convite: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> atualizarStatusAmizade(String cervejeiroId, String novoStatus, BuildContext context) async {
    final usuarioAtual = Supabase.instance.client.auth.currentUser?.id;
    if (usuarioAtual == null) return;

    final amizade = await buscarAmizade(cervejeiroId);
    if (amizade == null) return;

    final id = amizade['id'];

    await Supabase.instance.client
      .from('amizades')
      .update({'status': novoStatus})
      .eq('id', id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(novoStatus == 'aceito'
          ? 'Amizade aceita com sucesso!'
          : 'Solicitação recusada.'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Cervejeiro> get cervejeirosFiltradosOrdenados {
    final String meuId = Supabase.instance.client.auth.currentUser?.id ?? '';

    List<Cervejeiro> lista = _cervejeiros.where((c) =>
      c.visivelPesquisa &&
      c.id != meuId &&
      (_estadoSelecionado.isEmpty || c.estado == _estadoSelecionado)
    ).toList();

    lista.sort((a, b) {
      final statusA = statusOrdenacao(a.id);
      final statusB = statusOrdenacao(b.id);

      if (statusA != statusB) {
        return statusA.compareTo(statusB);
      }

      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });

    return lista;
  }

}
