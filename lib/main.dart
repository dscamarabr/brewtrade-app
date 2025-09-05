import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

// Screens
import 'screens/autenticacao.dart';
import 'screens/perfil.dart';
import 'screens/cadastro_cerveja.dart';
import 'screens/minhas_cervejas.dart';
import 'screens/cervejeiros_amigos.dart';
import 'screens/cervejas_amigos.dart';
import 'screens/menu_principal.dart';
import 'screens/notificacoes.dart';
import 'screens/resetar_senha.dart';

// Providers
import 'services/cerveja_provider.dart';
import 'services/perfil_provider.dart';
import 'services/tema_provider.dart';
import 'services/cervejeiro_provider.dart';
import 'services/cerveja_amigos_provider.dart';
import 'services/api_service.dart';
import 'services/notificacao_provider.dart';

// Models
import 'models/cerveja.dart';

// 🔔 Canal Android: ID precisa casar com o backend
const AndroidNotificationChannel kChannel = AndroidNotificationChannel(
  'cervejas_high', // mesmo ID que vamos enviar no index.ts
  'Cervejas', // Nome visível ao usuário
  description: 'Notificações importantes sobre cervejas',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Cria o canal no Android (somente na primeira execução)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(kChannel);
}

Future<void> handleIncomingLinkGlobal(Uri? uri) async {
  if (uri == null || uri.queryParameters['code'] == null) return;

  final supabase = Supabase.instance.client;
  final code = uri.queryParameters['code']!;
  final res = await supabase.auth.exchangeCodeForSession(code);

  if (res.session != null) {
    if (uri.host == 'login-callback') {
      await supabase.auth.signOut();

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('✅ E-mail confirmado com sucesso!'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 3));
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);

    } else if (uri.host == 'reset-password') {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/reset-password',
        (_) => false,
      );
    }
  }
}

Future<void> abrirTelaPorNotificacao({
  required int? idNotificacao,
  required Widget tela,
}) async {
  if (idNotificacao != null) {
    try {
      await navigatorKey.currentContext!
          .read<NotificacaoProvider>()
          .marcarComoLida(idNotificacao);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => tela),
  );
}

void _abrirTelaPorTipo(String? tipo, String idCervejeiro, int? idNotificacao) {
  final tipoNormalizado = tipo?.toLowerCase().replaceAll('_', ' ').trim();

  switch (tipoNormalizado) {
    case 'envio convite':
    case 'aceite convite':
      abrirTelaPorNotificacao(
        idNotificacao: idNotificacao,
        tela: ExplorarCervejeirosScreen(
          onVoltar: () {
            navigatorKey.currentState?.pushReplacementNamed('/notificacoes');
          },
        ),
      );
      break;

    case 'cadastro cerveja':
      abrirTelaPorNotificacao(
        idNotificacao: idNotificacao,
        tela: TelaCervejasAmigos(
          idCervejeiro: idCervejeiro,
          origem: "notificacoes",
        ),
      );
      break;

    default:
      navigatorKey.currentState?.pushNamed('/notificacoes');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🧪 Inicializa Supabase
  await Supabase.initialize(
    url: 'https://zkkctbgvbsevfjpnvwfe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpra2N0Ymd2YnNldmZqcG52d2ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MzU4MDUsImV4cCI6MjA2OTQxMTgwNX0.cZkS-BFeJhpbkObmeOCxvjEctcoRUWHwkef39yGO7wU',
  );

  await _initNotifications();

  // 🔔 Trata notificação que abriu o app fechado
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final idCervejeiro = initialMessage.data['usuario_id'];
    final idNotificacao = int.tryParse(initialMessage.data['id_notificacao'] ?? '');
    final tipo = initialMessage.data['tipo'];

    if (idCervejeiro != null) {
      _abrirTelaPorTipo(tipo, idCervejeiro, idNotificacao);
    }
  }

  // 🔔 Trata notificação com app em segundo plano
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final idCervejeiro = message.data['usuario_id'];
    final idNotificacao = int.tryParse(message.data['id_notificacao'] ?? '');
    final tipo = message.data['tipo'];

    if (idCervejeiro != null) {
      _abrirTelaPorTipo(tipo, idCervejeiro, idNotificacao);
    }
  });

  // Listener para mensagens em primeiro plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kChannel.id, // usa o mesmo ID criado
            kChannel.name,
            channelDescription: kChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  });

  final temaProvider = TemaProvider();
  await temaProvider.carregarTemaSalvo();

  final appLinks = AppLinks();

  // App fechado
  final initialUri = await appLinks.getInitialAppLink();
  if (initialUri != null) {
    handleIncomingLinkGlobal(initialUri);
  }

  // App aberto
  appLinks.uriLinkStream.listen((uri) {
    if (uri != null) {
      handleIncomingLinkGlobal(uri);
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CervejaProvider()),
        ChangeNotifierProvider(create: (_) => PerfilProvider()),
        ChangeNotifierProvider(create: (_) => CervejeiroProvider()),
        ChangeNotifierProvider(
          create: (_) => CervejaAmigosProvider(ApiService()),
        ),
        ChangeNotifierProvider.value(value: temaProvider),
        ChangeNotifierProvider(create: (_) => NotificacaoProvider()),
      ],
      child: const BrewTradeApp(),
    ),
  );
}

class BrewTradeApp extends StatelessWidget {
  const BrewTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TemaProvider>(
      builder: (context, temaProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'BrewTrade 🍺',
          theme: temaProvider.temaAtual,
          initialRoute: Supabase.instance.client.auth.currentUser == null
              ? '/auth'
              : '/menuPrincipal',
          routes: {
            '/auth': (context) => const AuthScreen(),
            '/menuPrincipal': (context) => MenuPrincipal(),
            '/perfil': (context) => const PerfilScreen(),
            '/cadastroCerveja': (context) => TelaCadastroCerveja(),
            '/minhasCervejas': (context) => TelaListaCervejas(),
            '/explorarCervejeiros': (context) =>
                const ExplorarCervejeirosScreen(),
            '/cervejasAmigos': (context) => const TelaCervejasAmigos(),
            '/notificacoes': (context) {
                final user = Supabase.instance.client.auth.currentUser;
                return TelaNotificacoes(
                  idUsuarioLogado: user?.id ?? '',
                );
              },
            '/reset-password': (_) => const ResetPasswordScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/cadastroCerveja' &&
                settings.arguments != null) {
              final cerveja = settings.arguments as Cerveja;
              return MaterialPageRoute(
                builder: (context) => TelaCadastroCerveja(cerveja: cerveja),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
