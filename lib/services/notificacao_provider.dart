import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notificacao.dart';

class NotificacaoProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<NotificacaoModel> _notificacoes = [];
  List<NotificacaoModel> get notificacoes => _notificacoes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> carregarNotificacoes(String idUsuarioLogado) async {
    // Marca como carregando sem notificar de imediato
    _isLoading = true;

    // Agenda a notificação para depois do frame atual
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

    _notificacoes = (data as List)
        .map((json) => NotificacaoModel.fromJson(json))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> marcarComoLida(int idNotificacao) async {
    await _client
        .from('tb_notificacoes')
        .update({'lido_em': DateTime.now().toIso8601String()})
        .eq('id_notificacao', idNotificacao);

    final index = _notificacoes.indexWhere((n) => n.id == idNotificacao);
    if (index != -1) {
      final atual = _notificacoes[index];
      _notificacoes[index] = NotificacaoModel(
        id: atual.id,
        tipo: atual.tipo,
        mensagem: atual.mensagem,
        criadoEm: atual.criadoEm,
        lidoEm: DateTime.now(),
        idRemetente: atual.idRemetente,
        nomeRemetente: atual.nomeRemetente,
        idDestinatario: atual.idDestinatario,
      );
      notifyListeners();
    }
  }

  Future<void> excluirNotificacao(int idNotificacao) async {
    await _client
        .from('tb_notificacoes')
        .delete()
        .eq('id_notificacao', idNotificacao);

    _notificacoes.removeWhere((n) => n.id == idNotificacao);
    notifyListeners();
  }

  void filtrarPorTipo(String tipo) {
    _notificacoes = _notificacoes
        .where((n) => n.tipo.toLowerCase() == tipo.toLowerCase())
        .toList();
    notifyListeners();
  }

  void restaurarLista(List<NotificacaoModel> todas) {
    _notificacoes = todas;
    notifyListeners();
  }
}
