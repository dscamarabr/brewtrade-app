import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/perfil_provider.dart';
import '../services/cervejeiro_provider.dart';
import '../services/cerveja_provider.dart';
import '../services/notificacao_provider.dart';
import '../services/cerveja_amigos_provider.dart';

import '../screens/autenticacao.dart';
import '../screens/minhas_cervejas.dart';
import '../screens/perfil.dart';
import '../screens/cadastro_cerveja.dart';
import '../screens/cervejeiros_amigos.dart';
import '../screens/cervejas_amigos.dart';
import '../screens/notificacoes.dart';
import '../screens/doacao.dart';
import '../screens/contato.dart';
import '../screens/contato_admin.dart';
import '../screens/quem_somos.dart';

class MenuPrincipal extends StatefulWidget {
  @override
  MenuPrincipalState createState() => MenuPrincipalState();
}

class MenuPrincipalState extends State<MenuPrincipal> {
  int _indiceAtual = 0;
  //String? _idCervejeiroSelecionado;
  Key? _cadastroKey = UniqueKey();

  // Controle de retorno ao sair da tela "Pesquisar Cervejas" (índice 4)
  // 0 = volta ao menu; 3 = volta à lista de cervejeiros
  int _indiceRetornoPesquisar = 0;

  void navegarParaCadastroNovaCerveja() {
    setState(() {
      _cadastroKey = UniqueKey();
      _indiceAtual = 2;
    });
  }

  void voltarParaMenu() {
    setState(() {
      _cadastroKey = UniqueKey();
      _indiceAtual = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    carregarPerfil().then((_) => carregarBadgeNotificacoes());
  }

  Future<void> carregarBadgeNotificacoes() async {
    final idUsuario = context.read<PerfilProvider>().id;
    if (idUsuario != null && idUsuario.isNotEmpty) {
      await context.read<NotificacaoProvider>().carregarNotificacoes(idUsuario);
    }
  }  

  Future<void> carregarPerfil() async {
    final perfilProvider = context.read<PerfilProvider>();
    await perfilProvider.carregarPerfil();

    final nome = perfilProvider.nome;

    if (nome == null || nome.trim().isEmpty) {
      if (!mounted) return;
      setState(() { _indiceAtual = 6; });

      Future.microtask(() {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete seu perfil antes de continuar'),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> navegarPara(int indice) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final perfil = context.read<PerfilProvider>();
    final cervejeiroProvider = context.read<CervejeiroProvider>();

    // Exige perfil completo (exceto na tela de perfil)
    if ((indice != 6) && (perfil.nome?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete seu perfil antes de acessar esta seção'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _indiceAtual = 6;
      });
      return;
    }

    if (indice == 1) {
      await context.read<CervejaProvider>().carregarCervejasDoBanco();
    } else if (indice == 3) {
      cervejeiroProvider.atualizarCervejeiros();
    } else if (indice == 4) {
      // Acesso "padrão" à tela de pesquisa (sem amigo pré-selecionado)
      //_idCervejeiroSelecionado = null;
      _indiceRetornoPesquisar = 0; // vindo do menu, volta ao menu
      final cervejaAmigosProvider = context.read<CervejaAmigosProvider>();
      cervejaAmigosProvider.limparFiltros();
      await cervejaAmigosProvider.carregarCervejasDosAmigos();
    }

    setState(() {
      _indiceAtual = indice;
    });
  }

  // Navegar diretamente para as cervejas de um amigo específico
  Future<void> verCervejasDoAmigo(String idCervejeiro) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final perfil = context.read<PerfilProvider>();
    if (perfil.nome == null || perfil.nome!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete seu perfil antes de acessar esta seção'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _indiceAtual = 6);
      return;
    }

    final cervejaAmigosProvider = context.read<CervejaAmigosProvider>();
    cervejaAmigosProvider.limparFiltros();

    cervejaAmigosProvider.aplicarFiltroPorIdCervejeiro(idCervejeiro);

    await cervejaAmigosProvider.carregarCervejasDosAmigos();

    setState(() {
      //_idCervejeiroSelecionado = idCervejeiro;
      _indiceRetornoPesquisar = 3; // vindo da lista de cervejeiros, volta pra lá
      _indiceAtual = 4; // vai para "Pesquisar Cervejas"
    });
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = [
      {
        'icone': SvgPicture.asset(
          'assets/icons/minhas_cervejas.svg',
          width: 96,
          height: 96,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        'titulo': 'Minhas Cervejas',
        'indice': 1
      },
      {
        'icone': SvgPicture.asset(
          'assets/icons/cadastrar-cerveja.svg',
          width: 96,
          height: 96,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        'titulo': 'Cadastrar Cerveja',
        'indice': 2
      },
      {
        'icone': SvgPicture.asset(
          'assets/icons/cervejeiros.svg',
          width: 96,
          height: 96,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        'titulo': 'Cervejeiros Amigos',
        'indice': 3
      },
      {
        'icone': SvgPicture.asset(
          'assets/icons/pesquisar_cerveja.svg',
          width: 96,
          height: 96,
          colorFilter: ColorFilter.mode(
            Theme.of(context).iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
        'titulo': 'Cervejas dos Amigos',
        'indice': 4
      },
      {
        'icone': Selector<NotificacaoProvider, int>(
          selector: (_, p) => p.naoLidas,
          builder: (_, count, __) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, size: 96),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        'titulo': 'Notificações',
        'indice': 5
      },
      {
        'icone': const Icon(Icons.person, size: 96),
        'titulo': 'Perfil Cervejeiro',
        'indice': 6
      },
    ];

    final fotoUrl = context.watch<PerfilProvider>().fotoUrl;
    Widget avatar;
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(fotoUrl),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      );
    } else {
      avatar = CircleAvatar(
        radius: 48,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondaryContainer),
      );
    }

    Widget _buildBody() {
      switch (_indiceAtual) {
        case 0:
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      avatar,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${context.watch<PerfilProvider>().nome ?? 'Cervejeiro'}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Hora de abrir uma Stout!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: 'Sair da conta',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            title: const Text('Confirmar logout'),
                            content: const Text('Tem certeza que deseja sair da conta?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: const Text('Sair'),
                                onPressed: () async {
                                  // Fecha o diálogo antes do await
                                  Navigator.of(dialogContext).pop();

                                  // Limpa dados locais antes de sair
                                  context.read<PerfilProvider>().limparPerfil();

                                  await Supabase.instance.client.auth.signOut();

                                  if (!mounted) return;

                                  Navigator.of(context, rootNavigator: true)
                                      .pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                                    (route) => false,
                                  );
                                }
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: opcoes.length,
                      itemBuilder: (context, index) {
                        final opcao = opcoes[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => navegarPara(opcao['indice'] as int),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(child: Center(child: opcao['icone'] as Widget)),
                                  const SizedBox(height: 8),
                                  Text(
                                    opcao['titulo'] as String,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );

        case 1:
          return TelaListaCervejas();

        case 2:
          return TelaCadastroCerveja(
            key: _cadastroKey,
            cerveja: null,
            onSalvar: () => setState(() => _indiceAtual = 1),
            onVoltar: voltarParaMenu,
          );

        case 3:
          return ExplorarCervejeirosScreen(
            onVoltar: () => setState(() => _indiceAtual = 0),
            onVerCervejasDoAmigo: (id) => verCervejasDoAmigo(id),
          );

        case 4:
          return TelaCervejasAmigos(origem: "menu");

        case 5:
          final idUsuario = context.watch<PerfilProvider>().id!;
          return TelaNotificacoes(
            idUsuarioLogado: idUsuario,
            onVoltar: () => setState(() => _indiceAtual = 0),
            onAbrirCervejasDoAmigo: (idCervejeiro) => verCervejasDoAmigo(idCervejeiro),
          );

        case 6:
          return PerfilScreen(onVoltar: () => setState(() => _indiceAtual = 0));

        default:
          return const Center(child: Text('Erro: Tela não encontrada'));
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Builder(
        builder: (context) {
          final perfil = context.watch<PerfilProvider>();

          // monta a lista base
          final items = <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Doação',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.contact_mail),
              label: 'Contato',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Quem Somos',
            ),
          ];

          // adiciona o Contato Admin se for admin
          if (perfil.isSuperAdmin) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: 'Contato Admin',
              ),
            );
          }

          return BottomNavigationBar(
            currentIndex: 0,
            selectedItemColor: Colors.grey,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDoacao()));
                  break;
                case 1:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TelaContato()));
                  break;
                case 2:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TelaQuemSomos()));
                  break;
                case 3:
                  if (perfil.isSuperAdmin) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TelaContatoAdmin()));
                  }
                  break;
              }
            },
            items: items,
          );
        },
      ),
    );

  }
}
