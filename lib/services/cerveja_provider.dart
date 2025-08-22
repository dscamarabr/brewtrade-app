import 'package:flutter/material.dart';
import '../models/cerveja.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

class CervejaProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Cerveja> _cervejas = [];
  String _filtroEstilo = 'Todos';
  String _ordenacao = 'Nome';

  bool _carregando = false;
  bool get carregando => _carregando;

  String get filtroEstilo => _filtroEstilo;
  String get ordenacao => _ordenacao;

  List<Cerveja> get cervejas => _cervejas;

  // 🔹 Lista filtrada + ordenada
  List<Cerveja> get cervejasFiltradas {
    List<Cerveja> lista = _filtroEstilo == 'Todos'
        ? List.from(_cervejas)
        : _cervejas.where((c) => c.estilo == _filtroEstilo).toList();

    lista.sort((a, b) {
      switch (_ordenacao) {
        case 'Nome':
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case 'ABV':
          return b.abv.compareTo(a.abv);
        case 'Estilo':
          return a.estilo.toLowerCase().compareTo(b.estilo.toLowerCase());
        default:
          return 0;
      }
    });

    return lista;
  }

  List<String> obterEstilosDisponiveis() {
    final todosEstilos = _cervejas.map((c) => c.estilo).toSet().toList();
    todosEstilos.sort();
    return todosEstilos;
  }

  void atualizarFiltro(String novoFiltro) {
    _filtroEstilo = novoFiltro;
    notifyListeners();
  }

  void atualizarOrdenacao(String novoCriterio) {
    _ordenacao = novoCriterio;
    notifyListeners();
  }

  void carregarCervejas(List<Cerveja> novaLista) {
    _cervejas = novaLista;
    notifyListeners();
  }

  void setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  Future<void> removerCerveja(Cerveja cerveja) async {
    try {
      await supabase
          .from('tb_cervejas')
          .delete()
          .eq('id_cerveja', cerveja.id_cerveja)
          .eq('id_usuario', cerveja.id_usuario);

      _cervejas.remove(cerveja);
      notifyListeners();
    } catch (e) {
      print('Erro ao excluir do Supabase: $e');
    }
  }

  void editarCerveja(Cerveja antiga, Cerveja nova) {
    final index = _cervejas.indexOf(antiga);
    if (index != -1) {
      _cervejas[index] = nova;
      notifyListeners();
    }
  }

  Future<void> carregarCervejasDoBanco() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setCarregando(true);

    final resposta = await supabase
        .from('tb_cervejas')
        .select()
        .eq('id_usuario', userId);

    _cervejas = resposta.map((e) => Cerveja.fromMap(e)).toList();

    setCarregando(false);
  }
}
