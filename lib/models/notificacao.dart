import 'package:flutter/material.dart';

class TipoNotificacao {
  static const cadastroCerveja = 'Cadastro Cerveja';
  static const envioConvite = 'Envio Convite';
  static const aceiteConvite = 'Aceite Convite';
  static const recusaConvite = 'Recusa Convite';
  static const cancelarConvite = 'Cancelar Convite';
}

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

  IconData get icone {
    switch (tipo) {
      case TipoNotificacao.envioConvite:
        return Icons.mail_outline;
      case TipoNotificacao.aceiteConvite:
        return Icons.check_circle_outline;
      case TipoNotificacao.recusaConvite:
        return Icons.cancel_outlined;
      case TipoNotificacao.cancelarConvite:
        return Icons.close;
      case TipoNotificacao.cadastroCerveja:
        return Icons.local_drink_outlined;
      default:
        return Icons.notifications;
    }
  }

}
