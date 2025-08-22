import 'package:flutter/material.dart'; // para widgets e visuais
import 'package:supabase_flutter/supabase_flutter.dart'; // para autenticação e consultas
import 'perfil_screen.dart';
import 'menu_principal.dart';

class TelaInicial extends StatefulWidget {
  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  bool _navegou = false;

  @override
  void initState() {
    super.initState();
    _verificarPerfil();
  }

  Future<void> _verificarPerfil() async {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null || _navegou) return;

    final perfil = await Supabase.instance.client
        .from('tb_cervejeiro')
        .select()
        .eq('id', usuario.id)
        .maybeSingle();

    if (!mounted || _navegou) return;

    _navegou = true;

    final Widget destino = perfil == null ? PerfilScreen() : MenuPrincipal();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

