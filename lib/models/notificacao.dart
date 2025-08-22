class NotificacaoModel {
  final int id;
  final String tipo;
  final String mensagem;
  final DateTime criadoEm;
  final DateTime? lidoEm;
  final String idRemetente;
  final String nomeRemetente;
  final String idDestinatario;

  NotificacaoModel({
    required this.id,
    required this.tipo,
    required this.mensagem,
    required this.criadoEm,
    this.lidoEm,
    required this.idRemetente,
    required this.nomeRemetente,
    required this.idDestinatario,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['id_notificacao'],
      tipo: json['tp_notificacao'],
      mensagem: json['mensagem_push'] ?? '',
      criadoEm: DateTime.parse(json['criado_em']),
      lidoEm: json['lido_em'] != null ? DateTime.parse(json['lido_em']) : null,
      idRemetente: json['id_usuario_remetente'],
      nomeRemetente: json['remetente_nome'], // agora direto da view
      idDestinatario: json['id_usuario_destinatario'],
    );
  }
}
