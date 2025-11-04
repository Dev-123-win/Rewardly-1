import 'dart:async';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Import the global sharedPreferences
import 'config_provider.dart'; // Import ConfigProvider

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  List<Map<String, dynamic>> _referredUsers = [];
  List<Map<String, dynamic>> get referredUsers => _referredUsers;

  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  StreamSubscription<QuerySnapshot>? _referralsStreamSubscription;

  // Referral related data
  String? _referralCode;
  String? get referralCode => _referralCode;

  // Local state for daily limits and pending writes
  Map<String, dynamic> _localDailyStats = {};
  Map<String, dynamic> get localDailyStats => _localDailyStats;
  List<Map<String, dynamic>> _pendingWrites = [];
  int _localWritesCount = 0;
  int _localReadsCount = 0;
  int get readsCount => _localReadsCount;
  int get writesCount => _localWritesCount;
  String _lastSyncDate = '';
  Timer? _syncTimer; // Timer for scheduled syncs
  final ConfigProvider? configProvider;

  UserProvider({this.configProvider}) {
    _loadLocalData(); // Load local data on startup
    _startScheduledSync(); // Start the periodic sync
  }

  @override
  void dispose() {
    _syncTimer?.cancel(); // Cancel the timer when the provider is disposed
    super.dispose();
  }

  Future<void> fetchUserData(String uid, {bool forceRefresh = false}) async {
    // Clear existing streams if any
    await _userStreamSubscription?.cancel();
    await _referralsStreamSubscription?.cancel();

    final String? cachedUser = sharedPreferences.getString('user_data_$uid');
    if (!forceRefresh && cachedUser != null) {
      _userData = json.decode(cachedUser);
      _referralCode = _userData?['referralCode'];
      notifyListeners();
    } else {
      incrementReadsCount();
    }

    // Set up user stream for real-time updates
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data();
        _referralCode = _userData?['referralCode'];
        sharedPreferences.setString('user_data_$uid', json.encode(_userData));
        notifyListeners();
      } else {
        _userData = null;
        _referralCode = null;
        sharedPreferences.remove('user_data_$uid');
        notifyListeners();
      }
    }, onError: (error) {
      // Handle stream errors, e.g., permissions denied
    });

    // Set up referrals stream
    _referralsStreamSubscription = FirebaseFirestore.instance
        .collection('referrals')
        .where('referrerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _referredUsers = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    }, onError: (error) {
      // Handle stream errors
    });

    // Also attempt to sync any pending writes
    _syncWritesToFirestore(force: true);
  }

  void clearUserData() {
    _userData = null;
    _referralCode = null;
    _referredUsers = [];
    _localDailyStats = {};
    _pendingWrites = [];
    _localWritesCount = 0;
    _localReadsCount = 0;
    _lastSyncDate = '';

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      sharedPreferences.remove('user_data_$currentUid');
      sharedPreferences.remove('user_data_last_fetched_$currentUid');
    }
    sharedPreferences.remove('localDailyStats');
    sharedPreferences.remove('pendingWrites');
    sharedPreferences.remove('localWritesCount');
    sharedPreferences.remove('localReadsCount');
    sharedPreferences.remove('lastSyncDate');
    sharedPreferences.remove('firestoreWritesCount_${DateTime.now().toIso8601String().substring(0, 10)}'); // Clear today's write count

    _userStreamSubscription?.cancel();
    _referralsStreamSubscription?.cancel();
    notifyListeners();
  }

  Future<void> redeemReferralCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in.");

    // No direct Firestore read here, as we're relying on the transaction to read
    // the referrer and app config. The transaction itself will increment read counts.

    final referrerQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get(); // This is a read, so increment count
    _localReadsCount++;
    await _saveLocalData();

    if (referrerQuery.docs.isEmpty) {
      throw Exception("Invalid referral code.");
    }

    final referrerDoc = referrerQuery.docs.first;
    final referrerId = referrerDoc.id;

    if (referrerId == user.uid) {
      throw Exception("Cannot redeem your own referral code.");
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final referrerRef = FirebaseFirestore.instance.collection('users').doc(referrerId);
    final appConfigRef = FirebaseFirestore.instance.collection('app_config').doc('settings');

    // The transaction reads will be counted by the transaction itself.
    // No need to manually increment here.

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final referrerUserDoc = await transaction.get(referrerRef);
      final appConfigDoc = await transaction.get(appConfigRef);

      if (!userDoc.exists || !referrerUserDoc.exists || !appConfigDoc.exists) {
        throw Exception("User, Referrer, or App Config not found.");
      }

      final userData = userDoc.data()!;
      if (userData['referredBy'] != null && userData['referredBy'] != '') {
        throw Exception("You have already redeemed a referral code.");
      }

      final appConfig = appConfigDoc.data()!;
      final int refereeBonus = appConfig['rewards']?['refereeBonus'] ?? 200;

      // Update referee's data
      _queueWrite({
        'type': 'user_update',
        'data': {
          'referredBy': code,
          'coinBalance': FieldValue.increment(refereeBonus),
          'totalEarned': FieldValue.increment(refereeBonus),
        },
      });

      // Create referral record
      _queueWrite({
        'type': 'referral_create',
        'data': {
          'referrerId': referrerId,
          'refereeId': user.uid,
          'refereeActiveDays': 0,
          'referrerRewarded': false,
          'refereeRewarded': true, // Referee gets reward immediately
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': null,
        },
      });

      // Create transaction for referee
      _queueWrite({
        'type': 'transaction',
        'data': {
          'userId': user.uid,
          'type': 'earning',
          'subType': 'referral',
          'amount': refereeBonus,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
          'metadata': {'referrerId': referrerId, 'referralCode': code},
        },
      });
    });
    notifyListeners();
  }

  Future<void> updateActiveDays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final String today = DateTime.now().toIso8601String().substring(0, 10);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      List<String> activeDays = List<String>.from(userData['activeDays'] ?? []);
      String lastActiveDate = userData['lastActiveDate'] ?? '';

      if (lastActiveDate != today) {
        activeDays.add(today);
        _queueWrite({
          'type': 'user_update',
          'data': {
            'activeDays': activeDays,
            'lastActiveDate': today,
          },
        });

        // Check if this user was referred and update refereeActiveDays
          if (userData['referredBy'] != null && userData['referredBy'] != '') {
            // This is a read, so increment count
            final referralQuery = await FirebaseFirestore.instance
                .collection('referrals')
                .where('refereeId', isEqualTo: user.uid)
                .where('referrerRewarded', isEqualTo: false)
                .limit(1)
                .get();
            _localReadsCount++;
            await _saveLocalData();

          if (referralQuery.docs.isNotEmpty) {
            final referralDoc = referralQuery.docs.first;
            final referralRef = referralDoc.reference;
            int currentActiveDays = referralDoc.data()['refereeActiveDays'] ?? 0;

            if (currentActiveDays < 3) {
              _queueWrite({
                'type': 'referral_update',
                'docRef': referralRef,
                'data': {
                  'refereeActiveDays': FieldValue.increment(1),
                },
              });

              if (currentActiveDays + 1 == 3) {
                // Award referrer bonus
                final referrerId = referralDoc.data()['referrerId'];
                final referrerRef = FirebaseFirestore.instance.collection('users').doc(referrerId);
                final appConfigRef = FirebaseFirestore.instance.collection('app_config').doc('settings');

                // The transaction reads will be counted by the transaction itself.
                // No need to manually increment here.

                final referrerUserDoc = await transaction.get(referrerRef);
                final appConfigDoc = await transaction.get(appConfigRef);

                if (referrerUserDoc.exists && appConfigDoc.exists) {
                  final appConfig = appConfigDoc.data()!;
                  final int referrerBonus = appConfig['rewards']?['referrerBonus'] ?? 500;

                  _queueWrite({
                    'type': 'user_update',
                    'docRef': referrerRef,
                    'data': {
                      'coinBalance': FieldValue.increment(referrerBonus),
                      'totalEarned': FieldValue.increment(referrerBonus),
                    },
                  });

                  _queueWrite({
                    'type': 'referral_update',
                    'docRef': referralRef,
                    'data': {
                      'referrerRewarded': true,
                      'completedAt': FieldValue.serverTimestamp(),
                    },
                  });

                  // Create transaction for referrer
                  _queueWrite({
                    'type': 'transaction',
                    'data': {
                      'userId': referrerId,
                      'type': 'earning',
                      'subType': 'referral_bonus',
                      'amount': referrerBonus,
                      'timestamp': FieldValue.serverTimestamp(),
                      'status': 'completed',
                      'metadata': {'refereeId': user.uid, 'referralCode': userData['referredBy']},
                    },
                  });
                }
              }
            }
          }
        }
      }
    });
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);

    _lastSyncDate = sharedPreferences.getString('lastSyncDate') ?? '';
    final String? dailyStatsJson = sharedPreferences.getString('localDailyStats');
    final String? pendingWritesJson = sharedPreferences.getString('pendingWrites');
    final String? localWritesCount = sharedPreferences.getString('localWritesCount');
    final String? localReadsCount = sharedPreferences.getString('localReadsCount');

    if (dailyStatsJson != null) {
      _localDailyStats = jsonDecode(dailyStatsJson) as Map<String, dynamic>;
    } else {
      _localDailyStats = {};
    }

    if (pendingWritesJson != null) {
      _pendingWrites = (jsonDecode(pendingWritesJson) as List).map((e) => e as Map<String, dynamic>).toList();
    } else {
      _pendingWrites = [];
    }

    _localWritesCount = int.tryParse(localWritesCount ?? '0') ?? 0;
    _localReadsCount = int.tryParse(localReadsCount ?? '0') ?? 0;

    if (_lastSyncDate != today) {
      // Reset Firestore write count if it's a new day
      await sharedPreferences.setInt('firestoreWritesCount_$today', 0);
    }

    // Reset daily stats if it's a new day
    if (_lastSyncDate != today) {
      _localDailyStats = {};
      _localWritesCount = 0;
      _localReadsCount = 0;
      _lastSyncDate = today;
      await _saveLocalData(); // Save the reset data
    }
    notifyListeners();
  }

  Future<void> _saveLocalData() async {
    await sharedPreferences.setString('localDailyStats', jsonEncode(_localDailyStats));
    await sharedPreferences.setString('pendingWrites', jsonEncode(_pendingWrites));
    await sharedPreferences.setString('localWritesCount', _localWritesCount.toString());
    await sharedPreferences.setString('localReadsCount', _localReadsCount.toString());
    await sharedPreferences.setString('lastSyncDate', _lastSyncDate);
  }

  void _queueWrite(Map<String, dynamic> writeOperation) {
    _pendingWrites.add(writeOperation);
    _localWritesCount++;
    _saveLocalData();
    notifyListeners();
    _scheduleSync();
  }

  Future<void> _syncWritesToFirestore({bool force = false}) async {
    if (_pendingWrites.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final batch = FirebaseFirestore.instance.batch();

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final int dailyWriteLimit = configProvider?.getConfig('dailyWriteLimit', defaultValue: 3) ?? 3;
    int currentFirestoreWrites = sharedPreferences.getInt('firestoreWritesCount_$today') ?? 0;

    if (!force && currentFirestoreWrites >= dailyWriteLimit) {
      return;
    }

    // Aggregate updates for user document
    Map<String, dynamic> userUpdates = {};
    List<Map<String, dynamic>> newTransactions = [];
    List<Map<String, dynamic>> newReferrals = [];
    List<Map<String, dynamic>> referralUpdates = [];
    List<Map<String, dynamic>> withdrawalRequests = [];

    for (var op in _pendingWrites) {
      if (op['type'] == 'user_update') {
        userUpdates.addAll(op['data']);
      } else if (op['type'] == 'transaction') {
        newTransactions.add(op['data']);
      } else if (op['type'] == 'referral_create') {
        newReferrals.add(op['data']);
      } else if (op['type'] == 'referral_update') {
        referralUpdates.add(op); // Keep docRef for updates
      } else if (op['type'] == 'withdrawal_request') {
        withdrawalRequests.add(op['data']);
      }
    }

    if (userUpdates.isNotEmpty) {
      batch.update(userRef, userUpdates);
    }

    for (var transactionData in newTransactions) {
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transactionRef, transactionData);
    }

    for (var referralData in newReferrals) {
      final referralRef = FirebaseFirestore.instance.collection('referrals').doc();
      batch.set(referralRef, referralData);
    }

    for (var referralUpdate in referralUpdates) {
      final DocumentReference docRef = referralUpdate['docRef'];
      batch.update(docRef, referralUpdate['data']);
    }

    for (var withdrawalData in withdrawalRequests) {
      final withdrawalRef = FirebaseFirestore.instance.collection('withdrawals').doc();
      batch.set(withdrawalRef, withdrawalData);
    }

    try {
      await batch.commit();
      _pendingWrites.clear();
      incrementWritesCount();
      await _saveLocalData(); // Save local data after successful sync

      // Update Firestore write count locally
      currentFirestoreWrites++;
      await sharedPreferences.setInt('firestoreWritesCount_$today', currentFirestoreWrites);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Schedule a sync operation (immediate, for when a write is queued)
  void _scheduleSync() {
    // Debounce multiple calls to _scheduleSync within a short period
    _syncTimer?.cancel(); // Cancel any existing immediate sync timer
    _syncTimer = Timer(const Duration(seconds: 5), () {
      if (_pendingWrites.isNotEmpty) {
        _syncWritesToFirestore();
      }
    });
  }

  void incrementReadsCount() {
    _localReadsCount++;
    _saveLocalData();
    notifyListeners();
  }

  void incrementWritesCount() {
    _localWritesCount++;
    _saveLocalData();
    notifyListeners();
  }

  // Start a periodic sync for aggregated daily writes (e.g., every 6 hours)
  void _startScheduledSync() {
    // Cancel any existing periodic timer to avoid duplicates
    _syncTimer?.cancel();

    // Schedule a periodic timer to sync writes every 6 hours
    _syncTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      if (_pendingWrites.isNotEmpty) {
        _syncWritesToFirestore();
      }
    });
  }


  Future<void> claimDailyReward(int dailyRewardAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception("User not found");
        }

        final userData = userDoc.data()!;

        final String today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
        final String lastActiveDate = userData['lastActiveDate'] ?? '';
        final Map<String, dynamic> dailyStats = userData['dailyStats'] ?? {};
        final Map<String, dynamic> todayStats = dailyStats[today] ?? {};

        final bool dailyRewardClaimed = todayStats['dailyRewardClaimed'] ?? false;

        if (dailyRewardClaimed || lastActiveDate == today) {
          throw Exception("Daily reward already claimed today or user not active on a new day.");
        }

        final int currentBalance = userData['coinBalance'] ?? 0;
        final int totalEarned = userData['totalEarned'] ?? 0;

        // Update local daily stats
        _localDailyStats[today] = {
          ...(_localDailyStats[today] ?? {}),
          'dailyRewardClaimed': true,
        };
        _localWritesCount++;

        // Queue write operations
        _queueWrite({
          'type': 'user_update',
          'data': {
            'coinBalance': currentBalance + dailyRewardAmount,
            'totalEarned': totalEarned + dailyRewardAmount,
            'lastActiveDate': today,
            'activeDays': FieldValue.arrayUnion([today]),
            'dailyStats.$today.dailyRewardClaimed': true,
            'dailyStats.$today.writesCount': FieldValue.increment(1),
          },
        });
        _queueWrite({
          'type': 'transaction',
          'data': {
            'userId': user.uid,
            'type': 'earning',
            'subType': 'daily_reward',
            'amount': dailyRewardAmount,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'metadata': {'date': today},
          },
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> watchAdAndEarnCoins(int adRewardAmount, int dailyAdLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception("User not found");
        }

        final userData = userDoc.data()!;

        final String today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
        final Map<String, dynamic> dailyStats = userData['dailyStats'] ?? {};
        final Map<String, dynamic> todayStats = dailyStats[today] ?? {};

        final int adsWatchedToday = todayStats['adsWatched'] ?? 0;

        if (adsWatchedToday >= dailyAdLimit) {
          throw Exception("Daily ad watch limit reached.");
        }

        final int currentBalance = userData['coinBalance'] ?? 0;
        final int totalEarned = userData['totalEarned'] ?? 0;

        // Update local daily stats
        _localDailyStats[today] = {
          ...(_localDailyStats[today] ?? {}),
          'adsWatched': (todayStats['adsWatched'] ?? 0) + 1,
        };
        _localWritesCount++;

        // Queue write operations
        _queueWrite({
          'type': 'user_update',
          'data': {
            'coinBalance': currentBalance + adRewardAmount,
            'totalEarned': totalEarned + adRewardAmount,
            'dailyStats.$today.adsWatched': FieldValue.increment(1),
            'dailyStats.$today.writesCount': FieldValue.increment(1),
          },
        });
        _queueWrite({
          'type': 'transaction',
          'data': {
            'userId': user.uid,
            'type': 'earning',
            'subType': 'ad',
            'amount': adRewardAmount,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'metadata': {'date': today, 'adCount': adsWatchedToday + 1},
          },
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> spinAndEarnCoins(int amount, int dailySpinLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception("User not found");
        }

        final userData = userDoc.data()!;

        final String today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
        final Map<String, dynamic> dailyStats = userData['dailyStats'] ?? {};
        final Map<String, dynamic> todayStats = dailyStats[today] ?? {};

        final int spinsUsedToday = todayStats['spinsUsed'] ?? 0;

        if (spinsUsedToday >= dailySpinLimit) {
          throw Exception("Daily spin limit reached.");
        }

        final int currentBalance = userData['coinBalance'] ?? 0;
        final int totalEarned = userData['totalEarned'] ?? 0;

        // Update local daily stats
        _localDailyStats[today] = {
          ...(_localDailyStats[today] ?? {}),
          'spinsUsed': (todayStats['spinsUsed'] ?? 0) + 1,
        };
        _localWritesCount++;

        // Queue write operations
        _queueWrite({
          'type': 'user_update',
          'data': {
            'coinBalance': currentBalance + amount,
            'totalEarned': totalEarned + amount,
            'dailyStats.$today.spinsUsed': FieldValue.increment(1),
            'dailyStats.$today.writesCount': FieldValue.increment(1),
          },
        });
        _queueWrite({
          'type': 'transaction',
          'data': {
            'userId': user.uid,
            'type': 'earning',
            'subType': 'spin',
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'metadata': {'date': today, 'spinCount': spinsUsedToday + 1},
          },
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> playTicTacToeAndEarnCoins(int tictactoeRewardAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception("User not found");
        }

        final userData = userDoc.data()!;

        final String today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
        final Map<String, dynamic> dailyStats = userData['dailyStats'] ?? {};
        final Map<String, dynamic> todayStats = dailyStats[today] ?? {};

        final int tictactoeGamesToday = todayStats['tictactoeGames'] ?? 0;
        final int currentBalance = userData['coinBalance'] ?? 0;
        final int totalEarned = userData['totalEarned'] ?? 0;

        // Update local daily stats
        _localDailyStats[today] = {
          ...(_localDailyStats[today] ?? {}),
          'tictactoeGames': (todayStats['tictactoeGames'] ?? 0) + 1,
        };
        _localWritesCount++;

        // Queue write operations
        _queueWrite({
          'type': 'user_update',
          'data': {
            'coinBalance': currentBalance + tictactoeRewardAmount,
            'totalEarned': totalEarned + tictactoeRewardAmount,
            'dailyStats.$today.tictactoeGames': FieldValue.increment(1),
            'dailyStats.$today.writesCount': FieldValue.increment(1),
          },
        });
        _queueWrite({
          'type': 'transaction',
          'data': {
            'userId': user.uid,
            'type': 'earning',
            'subType': 'tictactoe',
            'amount': tictactoeRewardAmount,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'metadata': {'date': today, 'gameCount': tictactoeGamesToday + 1},
          },
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestWithdrawal(int amount, String method, Map<String, dynamic> details, int minWithdrawalCoins) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // No direct Firestore read here, as we're relying on the transaction to read.
    // The transaction itself will increment read counts.

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception("User not found");
        }

        final userData = userDoc.data()!;

        final int currentBalance = userData['coinBalance'] ?? 0;

        if (amount < minWithdrawalCoins) {
          throw Exception("Minimum withdrawal amount is $minWithdrawalCoins coins.");
        }

        if (amount > currentBalance) {
          throw Exception("Insufficient coin balance for withdrawal.");
        }

        // Update local state
        _localWritesCount++;

        // Queue write operations
        _queueWrite({
          'type': 'user_update',
          'data': {
            'coinBalance': currentBalance - amount,
            'totalWithdrawn': FieldValue.increment(amount),
            'dailyStats.${DateTime.now().toIso8601String().substring(0, 10)}.writesCount': FieldValue.increment(1),
          },
        });
        _queueWrite({
          'type': 'withdrawal_request',
          'data': {
            'userId': user.uid,
            'amount': amount,
            'method': method,
            'details': details,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          },
        });
        _queueWrite({
          'type': 'transaction',
          'data': {
            'userId': user.uid,
            'type': 'withdrawal',
            'subType': method == 'UPI' ? 'upi' : 'bank',
            'amount': -amount, // Negative for withdrawal
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
            'metadata': {'method': method, 'details': details},
          },
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> runDailyReconciliation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userData == null) return;

    final String userId = user.uid;
    final int localBalance = _userData!['coinBalance'] ?? 0;
    final int localTotalWithdrawn = _userData!['totalWithdrawn'] ?? 0;

    // This is a read-intensive operation and should be used sparingly.
    // It's intended for internal validation, not for frequent user-facing updates.
    _localReadsCount++; // Increment read count for this operation
    await _saveLocalData();

    try {
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      int calculatedBalance = 0;
      int calculatedWithdrawn = 0;

      for (var doc in transactionsSnapshot.docs) {
        final transaction = doc.data();
        final int amount = transaction['amount'] ?? 0;
        final String type = transaction['type'] ?? '';

        if (type == 'earning') {
          calculatedBalance += amount;
        } else if (type == 'withdrawal') {
          // Withdrawals are stored as negative amounts in transactions
          calculatedBalance += amount; // e.g., balance + (-500)
          calculatedWithdrawn += -amount; // e.g., withdrawn + 500
        }
      }

      if (calculatedBalance != localBalance || calculatedWithdrawn != localTotalWithdrawn) {
        // In a real app, you would log this to a server for investigation.
        // For example: await FirebaseAnalytics.instance.logEvent(name: 'reconciliation_failed', parameters: {'user_id': userId});
      } else {
        // Reconciliation successful
      }
    } catch (e) {
      // Log reconciliation error
    }
  }
}
