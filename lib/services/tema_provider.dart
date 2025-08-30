import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/temas.dart';

class TemaProvider extends ChangeNotifier {
  ThemeData _temaAtual = temaIPA;
  String _temaNome = 'ipa';

  ThemeData get temaAtual => _temaAtual;
  String get temaNome => _temaNome;

  Future<void> carregarTemaSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final temaSalvo = prefs.getString('temaSelecionado') ?? 'pilsen';
    //aplicarTemaPorNome(temaSalvo); desativado enquanto usamos apenas um tema
    aplicarTemaPorNome('ipa');
  }

  void aplicarTemaPorNome(String nome) async {
    switch (nome) {
      case 'pilsen':
        _temaAtual = temaPilsen;
        break;
      case 'ipa':
        _temaAtual = temaIPA;
        break;
      case 'stout':
        _temaAtual = temaStout;
        break;
      default:
        _temaAtual = temaPilsen;
    }
    _temaNome = nome;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temaSelecionado', nome);    
  }

  Future<void> aplicarTema(ThemeData novoTema, String nome) async {
    _temaAtual = novoTema;
    _temaNome = nome;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temaSelecionado', nome);
  }
}
