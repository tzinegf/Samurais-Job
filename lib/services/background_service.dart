import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

// Entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Flutter bindings are initialized
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Notifications inside the background isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Configure background service
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Bring to foreground notification to keep alive
    await service.setForegroundNotificationInfo(
      title: "Samurai Job",
      content: "Monitorando novas oportunidades...",
    );
  }

  // Start monitoring
  _startMonitoring(flutterLocalNotificationsPlugin);
}

// Function to initialize the service from the UI
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Explicitly create the channel in the main isolate as well to ensure it exists before startForeground
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Request permission explicitly for Android 13+
    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'samurai_job_background_service',
        'Samurai Job Background Service',
        description: 'Mantém o serviço de monitoramento ativo.',
        importance: Importance.low,
      ),
    );
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'samurai_job_background_service',
      initialNotificationTitle: 'Samurai Job',
      initialNotificationContent: 'Inicializando serviço de segundo plano...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onStartBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onStartBackground(ServiceInstance service) async {
  return true;
}

// Monitor Firestore for new requests and updates
void _startMonitoring(FlutterLocalNotificationsPlugin notificationsPlugin) {
  // Check auth state
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user == null) {
      print('BG SERVICE: Usuário não logado. Parando monitoramento.');
      return;
    }

    print('BG SERVICE: Usuário logado: ${user.uid}. Iniciando listener.');

    // Fetch user skills first
    List<String> userSkills = [];
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final List<dynamic> rawSkills = userData?['skills'] ?? [];
        userSkills = rawSkills.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print('BG SERVICE: Erro ao carregar skills: $e');
    }

    // 1. Listen for NEW SERVICE REQUESTS (Public)
    // We filter by createdAt to avoid flooding on restart
    // Removed 'status' filter to avoid Composite Index requirement
    // Using 10 minutes tolerance to avoid missing requests during startup
    final safeStartTime = DateTime.now().subtract(const Duration(minutes: 10));
    print('BG SERVICE: Monitorando pedidos criados após: $safeStartTime');

    FirebaseFirestore.instance
        .collection('service_requests')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(safeStartTime))
        .snapshots()
        .listen(
          (snapshot) {
            print(
              'BG SERVICE: Snapshot recebido com ${snapshot.docChanges.length} alterações',
            );
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                print(
                  "BG SERVICE: Novo documento detectado: ${change.doc.id}, Status: ${data['status']}",
                );

                // Manual filter for status
                if (data['status'] == 'pending') {
                  _processNewRequest(
                    data,
                    userSkills,
                    notificationsPlugin,
                    change.doc.id,
                  );
                }
              } else if (change.type == DocumentChangeType.removed) {
                // Cancel notification if request is deleted
                final docId = change.doc.id;
                print(
                  'BG SERVICE: Documento removido: $docId. Cancelando notificação.',
                );
                notificationsPlugin.cancel(docId.hashCode);
              } else if (change.type == DocumentChangeType.modified) {
                final data = change.doc.data() as Map<String, dynamic>;
                // Cancel notification if status changes to something other than pending (e.g. accepted by someone else)
                if (data['status'] != 'pending') {
                  final docId = change.doc.id;
                  print(
                    'BG SERVICE: Status alterado para ${data['status']}. Cancelando notificação de pendente.',
                  );
                  notificationsPlugin.cancel(docId.hashCode);
                }
              }
            }
          },
          onError: (e) {
            print('BG SERVICE: Erro no listener de pedidos: $e');
          },
        );

    // 2. Listen for QUOTES Updates (Proposal Accepted/Rejected)
    FirebaseFirestore.instance
        .collectionGroup('quotes')
        .where('professionalId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
          final prefs = await SharedPreferences.getInstance();
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final data = change.doc.data() as Map<String, dynamic>;
              final status = data['status'];
              final requestId =
                  data['requestId']; // Assuming requestId is in quote data

              if (status == 'accepted') {
                if (prefs.getBool('notified_success_$requestId') == true)
                  continue;

                _showNotification(
                  notificationsPlugin,
                  'Proposta Aceita! 🎉',
                  'Sua proposta foi aceita. Toque para ver detalhes.',
                  jsonEncode({'type': 'quote', 'requestId': requestId}),
                );
                await prefs.setBool('notified_success_$requestId', true);
              } else if (status == 'adjustment_requested') {
                if (prefs.getBool('notified_warning_$requestId') == true)
                  continue;

                _showNotification(
                  notificationsPlugin,
                  'Ajuste Solicitado ⚠️',
                  'O cliente solicitou um ajuste na sua proposta.',
                  jsonEncode({'type': 'quote', 'requestId': requestId}),
                );
                await prefs.setBool('notified_warning_$requestId', true);
              }
            }
          }
        }, onError: (e) => print('BG SERVICE: Erro quotes: $e'));

    // 3. Listen for CANCELLATIONS
    FirebaseFirestore.instance
        .collection('service_requests')
        .where('professionalId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
          final prefs = await SharedPreferences.getInstance();
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final data = change.doc.data() as Map<String, dynamic>;
              if (data['status'] == 'cancelled') {
                final docId = change.doc.id;
                if (prefs.getBool('notified_cancellation_$docId') == true)
                  continue;

                _showNotification(
                  notificationsPlugin,
                  'Serviço Cancelado',
                  'O serviço "${data['title']}" foi cancelado.',
                  jsonEncode({'type': 'cancellation', 'requestId': docId}),
                );
                await prefs.setBool('notified_cancellation_$docId', true);
              }
            }
          }
        }, onError: (e) => print('BG SERVICE: Erro cancellations: $e'));

    // 4. Listen for CHAT MESSAGES
    // Requires "receiverId" field in messages and Collection Group Index
    print(
      'BG SERVICE: Iniciando listener de mensagens para receiverId: ${user.uid}',
    );
    FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) async {
            final prefs = await SharedPreferences.getInstance();
            final currentChatId = prefs.getString('current_chat_id');

            print(
              'BG SERVICE: Snapshot de mensagens recebido. Docs: ${snapshot.docChanges.length}',
            );

            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                print(
                  'BG SERVICE: Nova mensagem detectada: ${change.doc.id}, Timestamp: $timestamp',
                );

                // Ignore old messages (before service start - 10 min buffer)
                if (timestamp != null && timestamp.isBefore(safeStartTime)) {
                  print('BG SERVICE: Mensagem antiga ignorada.');
                  continue;
                }

                final requestId = change.doc.reference.parent.parent?.id;

                // If we are currently in this chat, don't notify
                if (requestId != null && currentChatId == requestId) {
                  print(
                    'BG SERVICE: Mensagem recebida no chat ativo ($requestId). Ignorando notificação.',
                  );
                  continue;
                }

                final msgId = change.doc.id;
                if (prefs.getBool('notified_msg_$msgId') == true) {
                  print('BG SERVICE: Mensagem já notificada anteriormente.');
                  continue;
                }

                final senderName = data['senderName'] ?? 'Usuário';
                final messageBody = data['message'] ?? 'Nova mensagem';

                print(
                  'BG SERVICE: Criando notificação para mensagem de $senderName',
                );

                _showNotification(
                  notificationsPlugin,
                  'Nova mensagem de $senderName',
                  messageBody,
                  jsonEncode({
                    'type': 'chat',
                    'requestId': requestId,
                  }), // Payload to open chat
                );
                await prefs.setBool('notified_msg_$msgId', true);
              }
            }
          },
          onError: (e) {
            print('BG SERVICE: Erro chat messages: $e');
            if (e.toString().contains('index')) {
              print(
                '⚠️ AÇÃO NECESSÁRIA: Criar índice Collection Group para "messages" no campo "receiverId".',
              );
            }
          },
        );
  });
}

void _processNewRequest(
  Map<String, dynamic> data,
  List<String> userSkills,
  FlutterLocalNotificationsPlugin notificationsPlugin,
  String docId,
) async {
  if (userSkills.isEmpty) return;

  final category = data['category'] as String?;
  final subcategory = data['subcategory'] as String?;
  final service = data['service'] as String?;

  bool matchFound = false;
  if (category != null && userSkills.contains(category)) matchFound = true;
  if (subcategory != null && userSkills.contains(subcategory))
    matchFound = true;
  if (service != null && userSkills.contains(service)) matchFound = true;

  if (matchFound) {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notified_new_request_$docId') == true) {
      return;
    }

    print('BG SERVICE: Match encontrado! Disparando notificação para $docId');
    _showNotification(
      notificationsPlugin,
      'Novo Pedido: ${category ?? 'Serviço'}',
      '${data['title']} - Disponível para proposta',
      jsonEncode({'type': 'request', 'requestId': docId}),
    );
    await prefs.setBool('notified_new_request_$docId', true);
  }
}

Future<void> _showNotification(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  String title,
  String body,
  String? payload,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'samurai_job_channel_v2',
    'Samurai Job Notifications',
    channelDescription: 'Notificações importantes do Samurai Job',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFDE3344),
    enableVibration: true,
    playSound: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
    payload: payload,
  );
}
