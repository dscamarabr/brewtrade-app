class Amizade {
  final String id;
  final String id_cervejeiro_a;
  final String id_cervejeiro_b;
  final String status;

  Amizade({
    required this.id,
    required this.id_cervejeiro_a,
    required this.id_cervejeiro_b,
    required this.status,
  });

  factory Amizade.fromMap(Map<String, dynamic> map) {
    return Amizade(
      id: map['id'],
      id_cervejeiro_a: map['id_cervejeiro_a'],
      id_cervejeiro_b: map['id_cervejeiro_b'],
      status: map['status'],
    );
  }

  /// Retorna o ID do amigo, dado o ID do usuário atual
  String obterIdDoAmigo(String meuId) {
    if (meuId == id_cervejeiro_a) return id_cervejeiro_b;
    if (meuId == id_cervejeiro_b) return id_cervejeiro_a;
    throw Exception('ID informado não pertence à amizade');
  }

}
