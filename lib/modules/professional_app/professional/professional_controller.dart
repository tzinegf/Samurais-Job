import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/service_request_model.dart';
import '../../../utils/ranking_system.dart';
import '../../auth/auth_controller.dart';

class ProfessionalController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxList<ServiceRequestModel> _allPendingRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> availableRequests = <ServiceRequestModel>[].obs;
  RxList<ServiceRequestModel> myRequests = <ServiceRequestModel>[].obs;
  RxBool isLoading = false.obs;

  // Filtering and Location
  RxString currentFilter = 'recent'.obs; // 'recent', 'nearest', 'price_desc'
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  String? _previousRank;

  @override
  void onInit() {
    super.onInit();

    // Initialize previous rank
    _previousRank = _authController.currentUser.value?.ranking;

    // Setup listeners for filtering
    ever(_authController.currentUser, (user) {
      if (user != null) {
        if (_previousRank != null && _previousRank != user.ranking) {
          _showRankChangeNotification(user.ranking, _previousRank!);
        }
        _previousRank = user.ranking;
      }
      _filterRequests();
    });

    ever(_allPendingRequests, (_) => _filterRequests());
    ever(currentFilter, (_) => _filterRequests());
    ever(currentPosition, (_) => _filterRequests());

    fetchAvailableRequests();
    fetchMyRequests();
    getCurrentLocation();
  }

  void _showRankChangeNotification(String newRank, String oldRank) {
    // Basic mapping for checking direction (simple comparison or list index)
    // For now just a generic message or check if improved.
    // We can assume if it changed it's important.

    Get.dialog(
      AlertDialog(
        title: Text('Atualização de Ranking! 🥋'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seu nível de Samurai mudou!'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  oldRank.toUpperCase(),
                  style: TextStyle(color: Colors.grey),
                ),
                Icon(Icons.arrow_forward, color: Color(0xFFDE3344)),
                Text(
                  newRank.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDE3344),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Continue honrando o caminho do Samurai!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK', style: TextStyle(color: Color(0xFFDE3344))),
          ),
        ],
      ),
    );
  }

  void _filterRequests() {
    final user = _authController.currentUser.value;
    final skills = user?.skills ?? [];
    List<ServiceRequestModel> filtered;

    if (skills.isNotEmpty) {
      filtered = _allPendingRequests.where((req) {
        final reqCategory = req.category.toLowerCase().trim();
        final reqSubcategory = req.subcategory?.toLowerCase().trim();
        final reqService = req.service?.toLowerCase().trim();

        // Case insensitive and trim check
        return skills.any((skill) {
          final s = skill.toLowerCase().trim();

          if (s == reqCategory) return true;
          if (reqSubcategory != null && s == reqSubcategory) return true;
          if (reqService != null && s == reqService) return true;

          return false;
        });
      }).toList();
    } else {
      // Fallback: Show all if no skills defined
      filtered = _allPendingRequests.toList();
    }

    // Apply Sorting
    switch (currentFilter.value) {
      case 'nearest':
        if (currentPosition.value != null) {
          final Distance distance = Distance();
          filtered.sort((a, b) {
            final distA = (a.latitude != null && a.longitude != null)
                ? distance.as(
                    LengthUnit.Meter,
                    currentPosition.value!,
                    LatLng(a.latitude!, a.longitude!),
                  )
                : double.maxFinite
                      .toInt(); // Put items without location at the end

            final distB = (b.latitude != null && b.longitude != null)
                ? distance.as(
                    LengthUnit.Meter,
                    currentPosition.value!,
                    LatLng(b.latitude!, b.longitude!),
                  )
                : double.maxFinite.toInt();

            return distA.compareTo(distB);
          });
        }
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'recent':
      default:
        filtered.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
    }

    availableRequests.value = filtered;
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      currentPosition.value = LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Erro ao obter localização: $e");
    }
  }

  void fetchAvailableRequests() {
    // Realtime listener for pending requests
    _db
        .collection('service_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) {
            _allPendingRequests.value = snapshot.docs
                .map((doc) => ServiceRequestModel.fromDocument(doc))
                .toList();
          },
          onError: (e) {
            Get.snackbar(
              "Erro",
              "Falha ao carregar pedidos: $e",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          },
        );
  }

  void fetchMyRequests() {
    String? uid = _authController.firebaseUser.value?.uid;
    if (uid == null) return;

    _db
        .collection('service_requests')
        .where('professionalId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          myRequests.value = snapshot.docs
              .map((doc) => ServiceRequestModel.fromDocument(doc))
              .toList();
        });
  }

  static const int BASE_QUOTE_COST = 5;
  static const int EXCLUSIVE_QUOTE_COST = 10; // Double the base cost

  Future<void> sendQuote(
    ServiceRequestModel request,
    double price,
    String description,
    bool isExclusive,
  ) async {
    try {
      isLoading.value = true;
      final currentUser = _authController.currentUser.value;

      if (currentUser == null) {
        Get.snackbar(
          'Erro',
          'Usuário não identificado.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final requestRef = _db.collection('service_requests').doc(request.id);
      final userRef = _db.collection('users').doc(currentUser.id);
      final quotesRef = requestRef.collection('quotes');

      // Check if professional already has a quote for this request
      final existingQuoteQuery = await quotesRef
          .where('professionalId', isEqualTo: currentUser.id)
          .limit(1)
          .get();

      final existingQuoteDoc = existingQuoteQuery.docs.isNotEmpty
          ? existingQuoteQuery.docs.first
          : null;

      // If updating, we don't charge coins again
      final cost = (isExclusive && existingQuoteDoc == null)
          ? EXCLUSIVE_QUOTE_COST
          : (existingQuoteDoc == null ? BASE_QUOTE_COST : 0);

      if (cost > 0 && (currentUser.coins ?? 0) < cost) {
        Get.snackbar(
          'Saldo Insuficiente',
          'Você precisa de $cost moedas para enviar este orçamento. Seu saldo: ${currentUser.coins ?? 0}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _db.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) {
          throw Exception("Pedido não encontrado.");
        }

        final requestData = requestSnapshot.data() as Map<String, dynamic>;
        final currentQuoteCount = requestData['quoteCount'] ?? 0;
        final currentIsExclusive = requestData['isExclusive'] ?? false;
        final exclusiveProId = requestData['exclusiveProfessionalId'];

        // Logic Checks
        if (currentIsExclusive && exclusiveProId != currentUser.id) {
          throw Exception("Este pedido é exclusivo de outro profissional.");
        }

        if (existingQuoteDoc == null &&
            currentQuoteCount >= 4 &&
            !isExclusive) {
          throw Exception("Limite de 4 orçamentos atingido para este pedido.");
        }

        if (cost > 0) {
          final userSnapshot = await transaction.get(userRef);
          final currentCoins = userSnapshot.data()?['coins'] ?? 0;
          if (currentCoins < cost) {
            throw Exception("Saldo insuficiente.");
          }
          // Deduct Coins
          transaction.update(userRef, {'coins': currentCoins - cost});
        }

        if (existingQuoteDoc != null) {
          // Update Existing Quote
          transaction.update(existingQuoteDoc.reference, {
            'price': price,
            'description': description,
            'isExclusive': isExclusive,
            'status': 'pending', // Reset status to pending (Waiting for client)
            'updatedAt': FieldValue.serverTimestamp(),
            'professionalRank': currentUser.ranking,
            'professionalRating': currentUser.rating,
            'professionalCompletedServices': currentUser.completedServicesCount,
          });
        } else {
          // Create New Quote
          final newQuoteRef = quotesRef.doc();
          transaction.set(newQuoteRef, {
            'professionalId': currentUser.id,
            'professionalName': currentUser.name,
            'professionalRank': currentUser.ranking,
            'professionalRating': currentUser.rating,
            'professionalCompletedServices': currentUser.completedServicesCount,
            'price': price,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'isExclusive': isExclusive,
            'status': 'pending',
          });

          // Update Request
          Map<String, dynamic> updateData = {
            'quoteCount': currentQuoteCount + 1,
            'quotedBy': FieldValue.arrayUnion([currentUser.id]),
          };

          if (isExclusive) {
            updateData['isExclusive'] = true;
            updateData['exclusiveProfessionalId'] = currentUser.id;
          }

          transaction.update(requestRef, updateData);
        }
      });

      // Refresh local data
      fetchAvailableRequests();
      fetchMyRequests();

      Get.back(); // Close dialog
      Get.snackbar(
        'Sucesso',
        existingQuoteDoc != null
            ? 'Orçamento atualizado com sucesso!'
            : 'Orçamento enviado com sucesso! ($cost moedas debitadas)',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Falha ao enviar orçamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void finishRequest({
    required String requestId,
    required String clientId,
    required double clientRating,
    required String clientReview,
    required bool professionalHasProblem,
    String? professionalProblemDescription,
  }) async {
    try {
      isLoading.value = true;

      // Ensure we have a valid clientId
      if (clientId.isEmpty) {
        throw Exception('ID do cliente inválido');
      }

      await _db.runTransaction((transaction) async {
        final requestRef = _db.collection('service_requests').doc(requestId);
        final clientRef = _db.collection('users').doc(clientId);

        // Read Client Data FIRST (Required for Firestore Transactions)
        final clientDoc = await transaction.get(clientRef);

        // Update Service Request
        transaction.update(requestRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'clientRating': clientRating,
          'clientReview': clientReview,
          'professionalHasProblem': professionalHasProblem,
          'professionalProblemDescription': professionalProblemDescription,
        });

        // Update Client's Rating if exists
        if (clientDoc.exists) {
          final data = clientDoc.data() as Map<String, dynamic>;
          final currentRating = (data['rating'] is int)
              ? (data['rating'] as int).toDouble()
              : (data['rating'] ?? 0.0).toDouble();
          final currentCount = data['ratingCount'] ?? 0;

          final newCount = currentCount + 1;
          final newRating =
              ((currentRating * currentCount) + clientRating) / newCount;

          transaction.update(clientRef, {
            'rating': newRating,
            'ratingCount': newCount,
          });
        }
      });

      Get.back(); // Close dialog
      Get.back(); // Close details bottom sheet
      Get.snackbar(
        "Sucesso",
        "Serviço finalizado e cliente avaliado com sucesso!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Erro ao finalizar serviço",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void cancelService(String requestId) async {
    try {
      isLoading.value = true;
      final user = _authController.currentUser.value;
      if (user == null) return;

      await _db.runTransaction((transaction) async {
        final requestRef = _db.collection('service_requests').doc(requestId);
        final professionalRef = _db.collection('users').doc(user.id);

        // Update Request
        transaction.update(requestRef, {
          'status': 'cancelled',
          'cancelledBy': 'professional',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // Update Professional Stats
        final professionalDoc = await transaction.get(professionalRef);
        if (professionalDoc.exists) {
          final data = professionalDoc.data() as Map<String, dynamic>;
          final currentCancellations = data['cancellationCount'] ?? 0;
          final newCancellations = currentCancellations + 1;

          final completedServices = data['completedServicesCount'] ?? 0;
          final rating = (data['rating'] is int)
              ? (data['rating'] as int).toDouble()
              : (data['rating'] ?? 0.0).toDouble();

          final newRank = RankingSystem.calculateRank(
            completedServices,
            rating,
            newCancellations,
          );

          transaction.update(professionalRef, {
            'cancellationCount': newCancellations,
            'ranking': newRank.toString().split('.').last,
          });
        }
      });

      Get.back(); // Close details
      Get.snackbar(
        "Serviço Cancelado",
        "O serviço foi cancelado. Atenção: Cancelamentos afetam seu ranking Samurai!",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } catch (e) {
      Get.snackbar(
        "Erro",
        "Erro ao cancelar serviço: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Temporary helper to create a dummy request for testing
  Future<void> createDummyRequest() async {
    var request = ServiceRequestModel(
      clientId: 'dummy_client_id',
      title: 'Reparo de Encanamento',
      description: 'Vazamento na pia da cozinha',
      category: 'Encanador',
      price: 150.0,
    );
    await _db.collection('service_requests').add(request.toJson());
  }
}
