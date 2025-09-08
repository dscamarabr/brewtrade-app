import 'package:flutter/material.dart';

class TelaBase extends StatelessWidget {
  final Widget child;
  final VoidCallback? onVoltar;

  const TelaBase({
    Key? key,
    required this.child,
    this.onVoltar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (onVoltar != null) {
          onVoltar!();
        } else {
          Navigator.of(context).pushReplacementNamed('/menuPrincipal');
        }
        return false; // impede o pop padrão
      },
      child: child,
    );
  }
}
