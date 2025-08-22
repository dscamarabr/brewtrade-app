import 'package:flutter/material.dart';
import '../models/cerveja.dart';
import '../services/api_service.dart';

class CervejaAmigosProvider extends ChangeNotifier {
  final ApiService _api;

  CervejaAmigosProvider(this._api);
  
  List<Cerveja> _todasCervejas = [];
  List<Cerveja> cervejasFiltradas = [];

  Map<String, String> _mapaCervejeiros = {}; // id_usuario → nome

  String _ordenacaoAtual = 'Nome';
  String _filtroEstilo = 'Todos';
  String _filtroCervejeiro = 'Todos';

  Future<void> carregarCervejasDosAmigos() async {
    final usuarioLogado = await _api.getUsuarioLogado(); 
    final meuId = usuarioLogado.id;
    final amizadesAceitas = await _api.getAmizadesDoUsuario()
      ..removeWhere((a) => a.status != 'aceito');

    final idsAmigos = amizadesAceitas
        .map((a) => a.obterIdDoAmigo(meuId))
        .toSet();

    final todasCervejas = await _api.getTodasCervejas();
    final cervejeiros = await _api.getTodosCervejeiros();

    _mapaCervejeiros = {
      for (var c in cervejeiros) c.id: c.nome ?? 'Desconhecido',
    };

    _todasCervejas = todasCervejas
        .where((c) => idsAmigos.contains(c.id_usuario))
        .map((c) => c.copyWith(descricao: _mapaCervejeiros[c.id_usuario])) // usando descricao como nome temporário
        .toList();

    aplicarFiltrosEOrdenacao();
  }

  void atualizarOrdenacao(String criterio) {
    _ordenacaoAtual = criterio;
    aplicarFiltrosEOrdenacao();
  }

  void atualizarFiltroEstilo(String estilo) {
    _filtroEstilo = estilo;
    aplicarFiltrosEOrdenacao();
  }

  void atualizarFiltroCervejeiro(String nome) {
    _filtroCervejeiro = nome;
    aplicarFiltrosEOrdenacao();
  }

  void aplicarFiltrosEOrdenacao() {
    List<Cerveja> lista = [..._todasCervejas];

    if (_filtroEstilo != 'Todos') {
      lista = lista.where((c) => c.estilo == _filtroEstilo).toList();
    }

    if (_filtroCervejeiro != 'Todos') {
      lista = lista.where((c) => c.descricao == _filtroCervejeiro).toList();
    }

    lista.sort((a, b) {
      switch (_ordenacaoAtual) {
        case 'Estilo':
          return a.estilo.toLowerCase().compareTo(b.estilo.toLowerCase());
        case 'ABV':
          return a.abv.compareTo(b.abv);
        case 'Cervejeiro':
          return (a.descricao ?? '').toLowerCase().compareTo((b.descricao ?? '').toLowerCase());
        case 'Nome':
        default:
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      }
    });

    cervejasFiltradas = lista;
    notifyListeners();
  }

  List<String> obterEstilosDisponiveis() {
    return _todasCervejas.map((c) => c.estilo).toSet().toList()..sort();
  }

  List<String> obterCervejeirosDisponiveis() {
    return _todasCervejas.map((c) => c.descricao ?? 'Desconhecido').toSet().toList()..sort();
  }

  void aplicarFiltroPorIdCervejeiro(String id) {
    final nome = _mapaCervejeiros[id];

    if (nome != null) {
      _filtroCervejeiro = nome;
      aplicarFiltrosEOrdenacao();
      notifyListeners();
    }
  }

  void limparFiltros() {
    _filtroEstilo = 'Todos';
    _filtroCervejeiro = 'Todos';
    _ordenacaoAtual = 'Nome';
    aplicarFiltrosEOrdenacao();
    notifyListeners();
  }

}
