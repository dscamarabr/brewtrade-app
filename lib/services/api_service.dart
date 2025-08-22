import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cerveja.dart';
import '../models/amizade.dart';
import '../models/cervejeiro.dart';


class ApiService {
  final client = Supabase.instance.client;

  Future<List<Cerveja>> getTodasCervejas() async {
    final response = await client
        .from('tb_cervejas')
        .select()
        .eq('situacao', 'Disponível para troca') 
        .order('nome', ascending: true);

    return (response as List)
        .map((map) => Cerveja.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Amizade>> getAmizadesDoUsuario() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('amizades')
        .select()
        .or('id_cervejeiro_a.eq.$userId,id_cervejeiro_b.eq.$userId');

    return (response as List)
        .map((map) => Amizade.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<List<Cervejeiro>> getTodosCervejeiros() async {
    final response = await client
        .from('tb_cervejeiro')
        .select();

    return (response as List)
        .map((map) => Cervejeiro.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  Future<Cervejeiro> getUsuarioLogado() async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Nenhum usuário logado');
    }

    // Supondo que você tenha uma tabela `tb_cervejeiro` com os dados do usuário
    final response = await client
        .from('tb_cervejeiro')
        .select()
        .eq('id', user.id)
        .single();

    return Cervejeiro.fromMap(response);
  }

}
