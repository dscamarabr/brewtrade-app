class Cerveja {
  final String id_cerveja;
  final String nome;
  final String cervejaria;
  final String estilo;
  final double abv;
  final int? ibu;
  final int volume;
  final int? quantidade;
  final String? descricao;
  final String situacao;
  final List<String>? imagens;
  final DateTime data_cadastro;
  final String id_usuario;

  Cerveja({
    required this.id_cerveja,
    required this.nome,
    required this.cervejaria,
    required this.estilo,
    required this.abv,
    this.ibu,
    required this.volume,
    this.quantidade,
    this.descricao,
    required this.situacao,
    this.imagens,
    required this.data_cadastro,
    required this.id_usuario,
  });

  factory Cerveja.fromMap(Map<String, dynamic> map) {
    return Cerveja(
      id_cerveja: map['id_cerveja'].toString(),
      nome: map['nome'],
      cervejaria: map['cervejaria'],
      estilo: map['estilo'],
      abv: map['abv'] is double ? map['abv'] : double.tryParse(map['abv'].toString()) ?? 0.0,
      ibu: map['ibu'] != null ? int.tryParse(map['ibu'].toString()) : null,
      volume: int.tryParse(map['volume']?.toString() ?? '') ?? 0,
      quantidade: map['quantidade'] != null ? int.tryParse(map['quantidade'].toString()) : null,
      descricao: map['descricao']?.toString() ?? '',
      situacao: map['situacao'],
      imagens: map['imagens'] is List ? List<String>.from(map['imagens']) : [],
      data_cadastro: map['data_cadastro'] != null ? DateTime.tryParse(map['data_cadastro'].toString()) ?? DateTime.now() : DateTime.now(),
      id_usuario: map['id_usuario'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_cerveja': id_cerveja,
      'nome': nome,
      'cervejaria': cervejaria,
      'estilo': estilo,
      'abv': abv,
      'ibu': ibu,
      'volume': volume,
      'quantidade': quantidade,
      'descricao': descricao,
      'situacao': situacao,
      'imagens': imagens,
      'data_cadastro': data_cadastro.toIso8601String(),
      'id_usuario': id_usuario,
    };
  }

  Cerveja copyWith({
    String? id_cerveja,
    String? nome,
    String? cervejaria,
    String? estilo,
    double? abv,
    int? ibu,
    int? volume,
    int? quantidade,
    String? descricao,
    String? situacao,
    List<String>? imagens,
    DateTime? data_cadastro,
    String? id_usuario,
  }) {
    return Cerveja(
      id_cerveja: id_cerveja ?? this.id_cerveja,
      nome: nome ?? this.nome,
      cervejaria: cervejaria ?? this.cervejaria,
      estilo: estilo ?? this.estilo,
      abv: abv ?? this.abv,
      ibu: ibu ?? this.ibu,
      volume: volume ?? this.volume,
      quantidade: quantidade ?? this.quantidade,
      descricao: descricao ?? this.descricao,
      situacao: situacao ?? this.situacao,
      imagens: imagens ?? this.imagens,
      data_cadastro: data_cadastro ?? this.data_cadastro,
      id_usuario: id_usuario ?? this.id_usuario,
    );
  }
}
