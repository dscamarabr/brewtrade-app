import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notificacao.dart';

class NotificacaoProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  // Lista original carregada do backend
  List<NotificacaoModel> _todasNotificacoes = [];

  // Lista que a UI consome (pode estar filtrada)
  List<NotificacaoModel> _notificacoes = [];
  List<NotificacaoModel> get notificacoes => _notificacoes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get naoLidas => _notificacoes.where((n) => n.lidoEm == null).length;

  /// Carrega notificações do usuário logado
  Future<void> carregarNotificacoes(String idUsuarioLogado) async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    // Buscar amigos aceitos
    final amigos = await _client
        .from('v_amigos_aceitos')
        .select('amigo_id')
        .eq('user_id', idUsuarioLogado);

    final idsAmigos = (amigos as List)
        .map((a) => a['amigo_id'] as String)
        .toList();

    // Buscar notificações
    final data = await _client
        .from('vw_notificacoes_com_remetente')
        .select()
        .eq('id_usuario_destinatario', idUsuarioLogado)
        .inFilter('id_usuario_remetente', idsAmigos)
        .order('criado_em', ascending: false);

    _todasNotificacoes = (data as List)
        .map((json) => NotificacaoModel.fromJson(json))
        .toList();

    _notificacoes = List.from(_todasNotificacoes);

    _isLoading = false;
    notifyListeners();
  }

  /// Marca uma notificação como lida
  Future<void> marcarComoLida(int idNotificacao) async {
    await _client
        .from('tb_notificacoes')
        .update({'lido_em': DateTime.now().toIso8601String()})
        .eq('id_notificacao', idNotificacao);

    final index = _notificacoes.indexWhere((n) => n.id == idNotificacao);
    if (index != -1) {
      final atual = _notificacoes[index];
      final atualizada = NotificacaoModel(
        id: atual.id,
        tipo: atual.tipo,
        mensagem: atual.mensagem,
        criadoEm: atual.criadoEm,
        lidoEm: DateTime.now(),
        idRemetente: atual.idRemetente,
        nomeRemetente: atual.nomeRemetente,
        idDestinatario: atual.idDestinatario,
      );

      _notificacoes[index] = atualizada;

      // Também atualiza na lista original
      final indexOriginal = _todasNotificacoes.indexWhere((n) => n.id == idNotificacao);
      if (indexOriginal != -1) {
        _todasNotificacoes[indexOriginal] = atualizada;
      }

      notifyListeners();
    }
  }

  /// Exclui notificação
  Future<void> excluirNotificacao(int idNotificacao) async {
    await _client
        .from('tb_notificacoes')
        .delete()
        .eq('id_notificacao', idNotificacao);

    _notificacoes.removeWhere((n) => n.id == idNotificacao);
    _todasNotificacoes.removeWhere((n) => n.id == idNotificacao);

    notifyListeners();
  }

  /// Filtro separado por tipo
  void filtrarPorTipo(String tipo) {
    _notificacoes = _todasNotificacoes.where((n) {
      return tipo.isEmpty || tipo == 'Todos'
          ? true
          : n.tipo.toLowerCase() == tipo.toLowerCase();
    }).toList();
    notifyListeners();
  }

  /// Filtro separado por remetente
  void filtrarPorRemetente(String idRemetente) {
    _notificacoes = _todasNotificacoes.where((n) {
      return idRemetente.isEmpty
          ? true
          : n.idRemetente == idRemetente;
    }).toList();
    notifyListeners();
  }

  /// Restaura lista completa
  void restaurarLista() {
    _notificacoes = List.from(_todasNotificacoes);
    notifyListeners();
  }

  /// Lista de remetentes únicos (id + nome)
  List<Map<String, String>> get remetentesUnicos {
    final lista = <Map<String, String>>[];
    final idsAdicionados = <String>{};

    for (var n in _todasNotificacoes) {
      if (!idsAdicionados.contains(n.idRemetente)) {
        idsAdicionados.add(n.idRemetente);
        lista.add({
          'id': n.idRemetente,
          'nome': n.nomeRemetente ?? 'Remetente desconhecido',
        });
      }
    }

    return lista;
  }
}
