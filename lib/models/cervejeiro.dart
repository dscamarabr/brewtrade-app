class Cervejeiro {
  final String id;
  final String? nome;
  final String? bio;
  final String? fotoUrl;
  final DateTime criadoEm;
  final String? estado;
  final String? cidade;
  final String? cervejaria;
  final String? telefone;
  final bool permiteNotificacoes;
  final bool visivelPesquisa;
  final String? redeSocial;

  Cervejeiro({
    required this.id,
    this.nome,
    this.bio,
    this.fotoUrl,
    required this.criadoEm,
    this.estado,
    this.cidade,
    this.cervejaria,
    this.telefone,
    this.permiteNotificacoes = true,
    this.visivelPesquisa = true,
    this.redeSocial,
  });

  factory Cervejeiro.fromMap(Map<String, dynamic> map) {
    return Cervejeiro(
      id: map['id'] as String,
      nome: map['nome'],
      bio: map['bio'],
      fotoUrl: map['fotoUrl'],
      criadoEm: DateTime.parse(map['criadoEm']),
      estado: map['estado'],
      cidade: map['cidade'],
      cervejaria: map['cervejaria'],
      telefone: map['telefone'],
      permiteNotificacoes: map['permite_notificacoes'] ?? true,
      visivelPesquisa: map['visivel_pesquisa'] ?? true,
      redeSocial: map['rede_social'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'bio': bio,
      'fotoUrl': fotoUrl,
      'criadoEm': criadoEm.toIso8601String(),
      'estado': estado,
      'cidade': cidade,
      'cervejaria': cervejaria,
      'telefone': telefone,
      'permite_notificacoes': permiteNotificacoes,
      'visivel_pesquisa': visivelPesquisa,
      'rede_social': redeSocial,
    };
  }
}
