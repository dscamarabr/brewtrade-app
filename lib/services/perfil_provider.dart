import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilProvider with ChangeNotifier {
  String? _id;
  String? _nome;
  String? _fotoUrl;
  String? _telefone;
  String? _estado;
  String? _cidade;
  String? _cervejaria;
  String? _bio;
  String? _redeSocial;
  bool _permiteNotificacoes = true;
  bool _visivelPesquisa = true;
  bool _isSuperAdmin = false;

  // Getters
  String? get id => _id;
  String? get nome => _nome;
  String? get fotoUrl => _fotoUrl;
  String? get telefone => _telefone;
  String? get estado => _estado;
  String? get cidade => _cidade;
  String? get cervejaria => _cervejaria;
  String? get bio => _bio;
  String? get redeSocial => _redeSocial;
  bool get permiteNotificacoes => _permiteNotificacoes;
  bool get visivelPesquisa => _visivelPesquisa;
  bool get isSuperAdmin => _isSuperAdmin;

  // Atualiza perfil completo
  void atualizarPerfil(Map<String, dynamic> dados) {
  
    _id = dados['id'] ?? _id;
    _nome = dados['nome'] ?? _nome;
    _fotoUrl = dados['fotoUrl'] ?? _fotoUrl;
    _telefone = dados['telefone'] ?? _telefone;
    _estado = dados['estado'] ?? _estado;
    _cidade = dados['cidade'] ?? _cidade;
    _cervejaria = dados['cervejaria'] ?? _cervejaria;
    _bio = dados['bio'] ?? _bio;
    _redeSocial = dados['rede_social'] ?? _redeSocial;
    _permiteNotificacoes = dados['permite_notificacoes'] ?? _permiteNotificacoes;
    _visivelPesquisa = dados['visivel_pesquisa'] ?? _visivelPesquisa;
    _isSuperAdmin = dados['is_super_admin'] ?? _isSuperAdmin;

    notifyListeners();
  }

  Future<void> carregarPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final resposta = await Supabase.instance.client
          .from('tb_cervejeiro')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      atualizarPerfil(resposta ?? {});
    } catch (e) {
      print('Erro ao carregar perfil: $e');
      atualizarPerfil({});
    }
  }

  void atualizarFoto(String novaUrl) {
    _fotoUrl = '$novaUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  void atualizarNome(String novoNome) {
    _nome = novoNome;
    notifyListeners();
  }

  Future<void> removerFoto() async {
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      final uri = Uri.parse(_fotoUrl!);
      final fileName = uri.pathSegments.last;

      try {
        await Supabase.instance.client.storage
            .from('perfil-fotos')
            .remove([fileName]);

        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('tb_cervejeiro')
              .update({'fotoUrl': null})
              .eq('id', userId);
        }
      } catch (e) {
        debugPrint('Erro ao apagar foto: $e');
      }
    }

    _fotoUrl = null;
    notifyListeners();
  }

  void limparPerfil() {
    _id = null;
    _nome = null;
    _fotoUrl = null;
    _telefone = null;
    _estado = null;
    _cidade = null;
    _cervejaria = null;
    _bio = null;
    _redeSocial = null;
    _permiteNotificacoes = true;
    _visivelPesquisa = true;
    _isSuperAdmin = false;
    notifyListeners();
  }
}
