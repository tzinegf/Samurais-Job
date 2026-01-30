import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../modules/auth/auth_controller.dart';
import '../models/service_request_model.dart';

class NotificationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Keep track of subscriptions to cancel them when user logs out
  final List<dynamic> _listeners = [];

  // Unread Count
  final RxInt unreadCount = 0.obs;

  // Avoid notifying about initial data load
  bool _isInitialized = false;
  DateTime _startTime = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    print('DEBUG: NotificationService.onInit() chamado.');
    _initLocalNotifications();

    // Listen to auth changes to start/stop listening
    final authController = Get.find<AuthController>();
    ever(authController.currentUser, (user) {
      print('DEBUG: Auth user mudou: ${user?.id}');
      if (user != null && user.id != null) {
        _startListening(user.id!);
      } else {
        _stopListening();
      }
    });

    // If user is already logged in
    if (authController.currentUser.value != null &&
        authController.currentUser.value!.id != null) {
      print('DEBUG: Usuário já logado, iniciando listener imediatamente.');
      _startListening(authController.currentUser.value!.id!);
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped with payload: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('DEBUG: showLocalNotification chamado. ID: $id, Title: $title');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'samurai_job_channel_v2', // Changed ID to force update
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

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('DEBUG: Local Notification enviada com sucesso.');
    } catch (e) {
      print('ERRO ao enviar Local Notification: $e');
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    // 1. Show Local Notification IMMEDIATELY (independent of Firestore)
    // Using hashcode of relatedId or random if null, but ensuring unique ID logic
    int notificationId = relatedId != null
        ? relatedId.hashCode
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);

    showLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: relatedId,
    );

    // 2. Save to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'relatedId': relatedId,
          });

      // Snackbar as fallback/visual confirmation inside app
      Get.snackbar(
        title,
        body,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        duration: Duration(seconds: 4),
        icon: Icon(Icons.notifications_active, color: Color(0xFFDE3344)),
        onTap: (_) {
          // Handle tap if needed
        },
      );
    } catch (e) {
      print('Erro ao salvar notificação no Firestore: $e');
    }
  }

  void _startListening(String userId) {
    _stopListening(); // Clear any existing listeners
    _startTime = DateTime.now();
    _isInitialized = false;

    print('DEBUG: _startListening chamado para user $userId');
    print('DEBUG: _startTime definido para $_startTime');

    // 1. Listen to My Quotes (Proposal Updates)
    // Using Collection Group Query to find all quotes by this professional
    final quotesStream = _firestore
        .collectionGroup('quotes')
        .where('professionalId', isEqualTo: userId)
        .snapshots();

    bool isFirstQuotesLoad = true;
    final quotesSub = quotesStream.listen(
      (snapshot) {
        print(
          'DEBUG: Recebido snapshot de quotes. Docs: ${snapshot.docs.length}. Primeira carga: $isFirstQuotesLoad',
        );

        // Ignore initial snapshot to avoid processing existing quotes as new updates
        if (isFirstQuotesLoad) {
          isFirstQuotesLoad = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          print('DEBUG: Alteração detectada em quote. Tipo: ${change.type}');
          if (change.type == DocumentChangeType.modified ||
              change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final status = data['status'];
            // Prefer getting requestId from data if available, otherwise fallback to path
            final requestId =
                data['requestId'] ?? change.doc.reference.parent.parent?.id;

            print('DEBUG: Status: $status, RequestId: $requestId');

            if (requestId != null) {
              _handleQuoteStatusChange(userId, requestId, status, data);
            }
          }
        }
      },
      onError: (e) {
        print('ERRO NO STREAM DE QUOTES: $e');
        // Suppress snackbar to avoid interrupting user workflow
        // The link to create the index will be in the console logs
        if (e.toString().contains('index')) {
          print(
            '⚠️ AÇÃO NECESSÁRIA: Clique no link acima para criar o índice "quotes" (Collection Group) no Firebase Console.',
          );
        }
      },
    );
    _listeners.add(quotesSub);

    // 2. Listen to My Active Service Requests (Cancellations)
    final requestsStream = _firestore
        .collection('service_requests')
        .where('professionalId', isEqualTo: userId)
        .snapshots();

    bool isFirstRequestsLoad = true;
    final requestsSub = requestsStream.listen((snapshot) {
      if (isFirstRequestsLoad) {
        isFirstRequestsLoad = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final status = data['status'];

          if (status == 'cancelled') {
            _createNotification(
              userId: userId,
              title: 'Serviço Cancelado',
              body: 'O serviço "${data['title']}" foi cancelado pelo cliente.',
              type: 'cancellation',
              relatedId: change.doc.id,
            );
          }
        }
      }
    }, onError: (e) => print('ERRO NO STREAM DE REQUESTS: $e'));
    _listeners.add(requestsSub);

    // 3. Listen for New Requests (Global)
    // Removed 'status' filter from query to avoid Composite Index requirement during development.
    // We filter status in Dart code instead.

    // NOTE: We rely on 'createdAt' to avoid loading all history.
    // If testing with same device, ensure clocks are synced or use a slightly earlier time.
    // Using 24 hours ago to be absolutely safe during testing.
    final safeStartTime = DateTime.now().subtract(Duration(hours: 24));
    print('DEBUG: Buscando novos pedidos criados após: $safeStartTime');

    final newRequestsStream = _firestore
        .collection('service_requests')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(safeStartTime))
        .snapshots();

    final newRequestsSub = newRequestsStream.listen(
      (snapshot) {
        print(
          'DEBUG: Stream de novos pedidos recebeu ${snapshot.docChanges.length} alterações.',
        );

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;

            // Filter by status (we only want pending requests)
            if (data['status'] != 'pending') {
              print(
                'DEBUG: Pedido ignorado pois status não é pending: ${data['status']}',
              );
              return;
            }

            // Filter by user skills/category
            final user = Get.find<AuthController>().currentUser.value;
            print(
              'DEBUG: User Skills: ${user?.skills}, Categoria do pedido: ${data['category']}',
            );

            if (user != null && user.id != null) {
              bool shouldNotify = true;

              // If user has skills defined, filter by category, subcategory, or service
              if (user.skills != null && user.skills!.isNotEmpty) {
                final category = data['category'] as String?;
                final subcategory = data['subcategory'] as String?;
                final service = data['service'] as String?;

                bool matchFound = false;

                // Check if any of the request's classification tags match the user's skills
                if (category != null && user.skills!.contains(category))
                  matchFound = true;
                if (subcategory != null && user.skills!.contains(subcategory))
                  matchFound = true;
                if (service != null && user.skills!.contains(service))
                  matchFound = true;

                if (!matchFound) {
                  print(
                    'DEBUG: Notificação ignorada. Nem Categoria ($category), Subcategoria ($subcategory) ou Serviço ($service) correspondem às habilidades: ${user.skills}',
                  );
                  shouldNotify = false;
                }
              }

              // Don't notify if the professional is the one who created the request (if using same account for testing)
              // if (data['clientId'] == user.id) {
              //    print('DEBUG: Notificação ignorada. Profissional é o autor do pedido.');
              //    shouldNotify = false;
              // }

              if (shouldNotify) {
                print(
                  'DEBUG: Nova notificação de pedido criada: ${data['title']}',
                );

                // Ensure notification runs on UI thread just in case
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _createNotification(
                    userId: user.id!,
                    title: 'Novo Pedido: ${data['category'] ?? 'Serviço'}',
                    body: '${data['title']} - Disponível para proposta',
                    type: 'new_request',
                    relatedId: change.doc.id,
                  );
                });
              }
            }
          }
        }
      },
      onError: (e) {
        print('ERRO NO STREAM DE NEW REQUESTS: $e');
      },
    );
    _listeners.add(newRequestsSub);

    // 4. Listen to Unread Notifications Count
    final unreadStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();

    final unreadSub = unreadStream.listen((snapshot) {
      unreadCount.value = snapshot.docs.length;
      print('DEBUG: Notificações não lidas: ${unreadCount.value}');
    });
    _listeners.add(unreadSub);

    _isInitialized = true;
  }

  void _stopListening() {
    for (var sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
    print('Serviço de notificações parado.');
  }

  Future<void> _handleQuoteStatusChange(
    String userId,
    String requestId,
    String? status, // Allow nullable
    Map<String, dynamic> data,
  ) async {
    String title = '';
    String message = '';
    String type = 'update';

    if (status == null) return;

    final normalizedStatus = status.trim();

    switch (normalizedStatus) {
      case 'accepted':
        title = 'Proposta Aceita! 🎉';
        message =
            'Sua proposta para o serviço foi aceita. Prepare-se para começar!';
        type = 'success';
        break;
      case 'rejected':
        title = 'Proposta Recusada';
        message =
            'Sua proposta não foi escolhida desta vez. Motivo: ${data['rejectionReason'] ?? 'Não informado'}';
        type = 'info';
        break;
      case 'adjustment_requested':
      case 'adjustmentRequested': // Fallback for camelCase
        title = 'Ajuste Solicitado ⚠️';
        message =
            'O cliente solicitou um ajuste na sua proposta: "${data['clientComment'] ?? data['comment'] ?? ''}"';
        type = 'warning';
        break;
      default:
        return; // Ignore other status changes
    }

    await _createNotification(
      userId: userId,
      title: title,
      body: message,
      type: type,
      relatedId: requestId,
    );
  }
}
