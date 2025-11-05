Complete Flutter Earning App Review & Optimization Plan
I'll analyze this project from both a senior developer perspective and an end-user lens, focusing on the critical Firestore optimization challenge and overall app quality.

📊 EXECUTIVE SUMMARY
Current State: The app has a solid feature foundation but will fail in production due to Firestore quota violations. Users will exceed the 5 reads/3 writes daily limit within hours of normal usage.
Critical Issues:

❌ Every action triggers immediate Firestore reads/writes
❌ No local caching strategy implemented
❌ UI lacks polish and consistency
❌ Ad integration logic needs optimization
❌ State management causes unnecessary rebuilds

Required Action: Implement a cache-first architecture with batched writes to stay within Firebase free tier limits while maintaining excellent UX.

1️⃣ TECHNICAL REVIEW (Developer Mode)
🏗️ Architecture Assessment
Current Structure:
lib/
├── main.dart (Provider setup)
├── providers/ (Business logic)
├── screens/ (UI)
└── widgets/ (Reusable components)
Issues:

No data layer separation - Providers directly access Firestore
No caching layer - Every operation hits network
Mixed concerns - UI logic mixed with data fetching
No offline-first strategy

Recommended Architecture:
lib/
├── data/
│   ├── models/
│   ├── repositories/ (Abstract data sources)
│   ├── cache/ (Hive/SharedPreferences)
│   └── remote/ (Firestore wrapper)
├── domain/
│   ├── entities/
│   └── usecases/
├── presentation/
│   ├── providers/
│   ├── screens/
│   └── widgets/
└── core/
    ├── constants/
    └── utils/

🔥 FIRESTORE LOGIC CRISIS ANALYSIS
Current Read/Write Pattern (BROKEN):
dart// ❌ CURRENT: User Provider - Each action = 1 read + 2 writes
Future<void> claimDailyReward(int amount) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final userDoc = await transaction.get(userRef); // READ #1
    // ... validation logic
    transaction.update(userRef, {...}); // WRITE #1
    transaction.set(transactionRef, {...}); // WRITE #2
  });
}

// Daily usage breakdown:
// - Claim daily reward: 1R + 2W
// - Watch 3 ads: 3R + 6W
// - Spin wheel 3x: 3R + 6W
// - Play 2 games: 2R + 4W
// TOTAL: 9 reads + 18 writes = QUOTA EXCEEDED BY 4PM
Problems Identified:

user_provider.dart (Lines 200-450):

Every earning method calls Firestore directly
No local state aggregation
Transactions create multiple writes per action
No write queue or batching mechanism


config_provider.dart (Lines 20-70):

Fetches config on every app launch (unnecessary reads)
Weekly cache refresh is good but needs enforcement


auth_provider.dart (Lines 50-150):

Device check reads Firestore every signup
Referral lookups unbatched




✅ PROPOSED FIRESTORE OPTIMIZATION SOLUTION
Core Strategy: Cache-First + Batched Writes
dart// 📦 NEW: CacheManager (Add to core/cache/)
class CacheManager {
  final SharedPreferences _prefs;
  static const String USER_DATA_KEY = 'user_data_cache';
  static const String LAST_SYNC_KEY = 'last_sync_timestamp';
  
  // Cache user data for 24 hours
  Future<AppUser?> getCachedUser() async {
    final String? cached = _prefs.getString(USER_DATA_KEY);
    final int? lastSync = _prefs.getInt(LAST_SYNC_KEY);
    
    if (cached != null && lastSync != null) {
      final hoursSinceSync = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastSync)
      ).inHours;
      
      if (hoursSinceSync < 24) {
        return AppUser.fromJson(json.decode(cached));
      }
    }
    return null;
  }
  
  Future<void> cacheUser(AppUser user) async {
    await _prefs.setString(USER_DATA_KEY, json.encode(user.toJson()));
    await _prefs.setInt(LAST_SYNC_KEY, DateTime.now().millisecondsSinceEpoch);
  }
}

// 📝 NEW: WriteQueue (Add to data/repositories/)
class WriteQueue {
  final List<Map<String, dynamic>> _pendingWrites = [];
  Timer? _syncTimer;
  
  void queueWrite(WriteOperation operation) {
    _pendingWrites.add(operation.toJson());
    _saveQueueToCache(); // Persist across app restarts
    _scheduleSync();
  }
  
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(Duration(hours: 6), () async {
      await _batchSyncToFirestore();
    });
  }
  
  Future<void> _batchSyncToFirestore() async {
    if (_pendingWrites.isEmpty) return;
    
    // Aggregate all writes into 3 operations max
    final batch = FirebaseFirestore.instance.batch();
    
    // 1. User document update (aggregated stats)
    final aggregatedUserUpdate = _aggregateUserUpdates(_pendingWrites);
    batch.update(userRef, aggregatedUserUpdate);
    
    // 2. Transaction documents (bulk create)
    for (var txn in _pendingWrites.where((w) => w['type'] == 'transaction')) {
      batch.set(FirebaseFirestore.instance.collection('transactions').doc(), txn);
    }
    
    // 3. Referral/withdrawal updates (if any)
    // ... similar aggregation
    
    await batch.commit(); // SINGLE WRITE OPERATION
    _pendingWrites.clear();
    _saveQueueToCache();
  }
}
Implementation Per Feature:
1. Daily Reward (Refactored)
dart// ✅ FIXED: Instant UI update, delayed write
Future<void> claimDailyReward(int amount) async {
  // 1. Update local cache immediately (0 reads, 0 writes)
  final updatedUser = _currentUser!.copyWith(
    coinBalance: _currentUser!.coinBalance + amount,
    totalEarned: _currentUser!.totalEarned + amount,
  );
  
  await _cacheManager.cacheUser(updatedUser);
  _currentUser = updatedUser;
  notifyListeners(); // UI updates instantly
  
  // 2. Queue write for later batch sync
  _writeQueue.queueWrite(WriteOperation(
    type: 'user_update',
    data: {'coinBalance': FieldValue.increment(amount)},
  ));
  
  _writeQueue.queueWrite(WriteOperation(
    type: 'transaction',
    data: {
      'userId': currentUser!.uid,
      'type': 'earning',
      'subType': 'daily_reward',
      'amount': amount,
    },
  ));
}
2. Watch Ads (Optimized)
dart// ✅ FIXED: No Firestore reads during ad watch
Future<void> recordAdWatch(int amount) async {
  // 1. Validate against local cache
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final todayStats = _currentUser!.todayStats;
  final adsWatched = todayStats['adsWatched'] ?? 0;
  
  if (adsWatched >= _dailyAdLimit) {
    throw Exception('Daily limit reached');
  }
  
  // 2. Update local cache
  final updatedUser = _currentUser!.copyWith(
    coinBalance: _currentUser!.coinBalance + amount,
    dailyStats: {
      ..._currentUser!.dailyStats,
      today: {...todayStats, 'adsWatched': adsWatched + 1}
    },
  );
  
  await _cacheManager.cacheUser(updatedUser);
  _currentUser = updatedUser;
  notifyListeners();
  
  // 3. Queue write
  _writeQueue.queueWrite(WriteOperation(
    type: 'user_update',
    data: {
      'coinBalance': FieldValue.increment(amount),
      'dailyStats.$today.adsWatched': FieldValue.increment(1),
    },
  ));
}
3. App Launch (Single Read)
dart// ✅ NEW: Fetch all data in one read
Future<void> initializeApp() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  // Check cache first
  final cachedUser = await _cacheManager.getCachedUser();
  
  if (cachedUser != null) {
    _currentUser = cachedUser;
    notifyListeners();
    return; // 0 reads used
  }
  
  // Only read from Firestore if cache expired
  final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get(); // READ #1 (only once per 24h)
  
  _currentUser = AppUser.fromFirestore(userDoc);
  await _cacheManager.cacheUser(_currentUser!);
  notifyListeners();
}
New Daily Quota Projection:
yamlReads per day:
  - App launch (24h cache): 1 read
  - Emergency refresh (manual): 0-1 read
  TOTAL: 1-2 reads ✅ (under 5 limit)

Writes per day:
  - Batched sync at 6h intervals: 3 writes max
  TOTAL: 3 writes ✅ (exactly at limit)

🎯 STATE MANAGEMENT ISSUES
Current Problems:

Excessive Rebuilds - Every Provider change rebuilds entire widget tree
No Selectors - Using Provider.of<T>(context) without granular listening
Memory Leaks - Streams not properly disposed in UserProvider

Fixes Needed:
dart// ❌ CURRENT: Rebuilds entire screen on any user change
class HomeTab extends StatelessWidget {
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context); // Rebuilds everything
    return Text('${userProvider.currentUser?.coinBalance}');
  }
}

// ✅ FIXED: Only rebuild coin display
class HomeTab extends StatelessWidget {
  Widget build(BuildContext context) {
    final coinBalance = context.select<UserProvider, int>(
      (provider) => provider.currentUser?.coinBalance ?? 0
    ); // Only rebuilds when coinBalance changes
    return Text('$coinBalance');
  }
}

🔒 SECURITY AUDIT
Critical Issues Found:

Exposed Firebase Keys (android/app/google-services.json, ios/Runner/GoogleService-Info.plist):

API keys visible in repository
Fix: Add to .gitignore, use environment variables


No Firestore Rules Enforcement:

javascript   // Current rules (firestore.rules) lack daily limit checks
   match /users/{userId} {
     allow read, update: if request.auth.uid == userId;
     // ❌ Missing: dailyLimits() validation
   }

Client-Side Ad Verification:

Coins awarded before server validation
Fix: Implement server-side reward verification via Cloud Functions (if budget allows) or stricter rules




📱 ADS LOGIC REVIEW
Current Issues in ad_provider.dart:
dart// ❌ Problem 1: No cooldown between ads
void showRewardedAd({required Function(RewardItem) onAdEarned}) {
  // User can spam button before ad loads
}

// ❌ Problem 2: No error handling for ad failures
rewardedAdLoadCallback: RewardedAdLoadCallback(
  onAdFailedToLoad: (error) {
    _isRewardedAdReady = false; // Just sets flag, no user feedback
  },
)

// ❌ Problem 3: Reward granted before ad completion verified
_rewardedAd!.show(
  onUserEarnedReward: (ad, reward) {
    onAdEarned(reward); // Coins awarded immediately, no validation
  },
);
Recommended Fixes:
dart// ✅ FIXED: Add cooldown and better error handling
class AdProvider with ChangeNotifier {
  DateTime? _lastAdShown;
  static const COOLDOWN_SECONDS = 30;
  
  bool get canShowAd {
    if (_lastAdShown == null) return true;
    return DateTime.now().difference(_lastAdShown!).inSeconds > COOLDOWN_SECONDS;
  }
  
  Future<void> showRewardedAdSafe({
    required Function(RewardItem) onAdEarned,
    required Function(String) onError,
  }) async {
    if (!canShowAd) {
      onError('Please wait $COOLDOWN_SECONDS seconds between ads');
      return;
    }
    
    if (_rewardedAd == null) {
      onError('Ad not ready. Please try again.');
      loadRewardedAd(); // Auto-reload
      return;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastAdShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onError('Ad failed to show: ${error.message}');
        ad.dispose();
        loadRewardedAd();
      },
    );
    
    _rewardedAd!.show(onUserEarnedReward: onAdEarned);
  }
}

2️⃣ UI/UX REVIEW (User Mode + Design Lens)
🎨 Overall Design Assessment
Current State: Basic Material Design with inconsistent spacing, generic colors, and placeholder content.
Issues:

No visual hierarchy
Inconsistent padding/margins
Generic blue color scheme
Missing micro-interactions
Poor empty states
No loading skeletons


📱 SCREEN-BY-SCREEN ANALYSIS
1. Splash Screen (splash_screen.dart)
Current Issues:
dart// Generic loading screen, no branding
Scaffold(
  body: Center(
    child: Column(
      children: [
        CircularProgressIndicator(), // Basic spinner
        Text('Loading...'), // Generic text
      ],
    ),
  ),
)
```

**User Experience:** Boring, no personality, feels unfinished

**Recommended Redesign:**
- Add app logo/icon with fade-in animation
- Use branded colors
- Show progress bar instead of spinner
- Add tagline: "Earn. Play. Withdraw."

**Mockup Description:**
```
┌─────────────────────────┐
│                         │
│                         │
│       [COIN ICON]       │ ← Animated coin flip
│                         │
│      Earning App        │ ← Bold, 32px
│   Earn. Play. Withdraw  │ ← Subtitle, 16px
│                         │
│   [Progress bar 80%]    │ ← Gradient progress
│                         │
└─────────────────────────┘
```

---

#### **2. Onboarding Screen** (onboarding_screen.dart)

**Current Issues:**
- Missing actual images (placeholders)
- Generic PageView dots
- Skip/Next buttons poorly positioned
- No animations

**Recommended Improvements:**
- Add illustration assets (use free resources like unDraw)
- Animate page transitions with scale/fade
- Modern bottom navigation dots
- Clear CTA: "Get Started" button with gradient

**Mockup Description (Page 1):**
```
┌─────────────────────────┐
│   [Skip]                │
│                         │
│   [Illustration:        │
│    Person watching      │
│    phone with coins]    │
│                         │
│   Earn Coins Daily      │ ← Bold title
│                         │
│   Watch ads, play games │ ← Body text
│   & claim rewards       │
│                         │
│   ● ○ ○                 │ ← Page indicators
│                         │
│   [Next →]              │ ← Rounded button
└─────────────────────────┘

3. Authentication Screen (auth_screen.dart)
Current Issues:
dart// Cluttered form with generic styling
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email address',
    filled: true,
    fillColor: Colors.grey[100], // Generic grey
  ),
)
Problems:

Google Sign-In button lacks official styling
Form validation errors not user-friendly
Password visibility toggle too small
Referral code input hidden in signup (should be prominent)

Recommended Redesign:

Use official Google sign-in button design
Add error messages with Icons
Larger touch targets (min 48x48dp)
Show referral code benefits upfront

Improved Code Snippet:
dart// ✅ Better Google Sign-In button
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _signInWithGoogle,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google_logo.png', height: 24),
          SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    ),
  ),
)

4. Home Screen (home_screen.dart)
CRITICAL ISSUES:
dart// ❌ Current: Generic list with poor hierarchy
Column(
  children: [
    ElevatedButton(
      onPressed: () => showDialog(...),
      child: Text('Claim Daily Reward'),
    ),
    ListTile(title: Text('Watch Ads')),
    ListTile(title: Text('Spin & Win')),
    // ...
  ],
)
```

**Problems:**
1. No visual distinction between earning methods
2. Coin balance shown in AppBar (hard to see)
3. Daily reward button looks like any other button
4. No progress indicators for daily limits
5. Missing stats/achievements section

**Recommended Complete Redesign:**

**New Home Screen Structure:**
```
┌─────────────────────────┐
│ [Profile]    [Coins: 245]│ ← Sticky header with gradient
├─────────────────────────┤
│                         │
│  ┌─────────────────────┐│
│  │ 🎁 Daily Reward     ││ ← Hero card, animated
│  │ Claim 10 coins now! ││
│  │ [Claim Now ✓]       ││
│  └─────────────────────┘│
│                         │
│  Earn More Coins        │ ← Section header
│  ┌──────┐ ┌──────┐     │
│  │ 📺   │ │ 🎰   │     │ ← Grid cards
│  │Watch │ │Spin &│     │
│  │ Ads  │ │ Win  │     │
│  │8/10  │ │2/3   │     │ ← Progress
│  └──────┘ └──────┘     │
│  ┌──────┐ ┌──────┐     │
│  │ 🎮   │ │ 💰   │     │
│  │Games │ │With- │     │
│  │      │ │draw  │     │
│  └──────┘ └──────┘     │
│                         │
│  Today's Earnings: +45  │ ← Stats bar
└─────────────────────────┘
Improved Code Structure:
dartclass HomeTab extends StatelessWidget {
  Widget build(BuildContext context) {
    final coinBalance = context.select<UserProvider, int>(
      (p) => p.currentUser?.coinBalance ?? 0
    );
    
    return CustomScrollView(
      slivers: [
        // Gradient app bar with coin balance
        SliverAppBar(
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6200EE), Color(0xFFBB86FC)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      '$coinBalance coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Daily reward hero card
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: DailyRewardCard(), // Separate widget
          ),
        ),
        
        // Earning methods grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildListDelegate([
              EarningMethodCard(
                icon: Icons.movie,
                title: 'Watch Ads',
                progress: '8/10',
                onTap: () => Navigator.pushNamed(context, WatchAdsScreen.routeName),
              ),
              // ... more cards
            ]),
          ),
        ),
      ],
    );
  }
}

// New reusable widget
class EarningMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String progress;
  final VoidCallback onTap;
  
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                progress,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

5. Watch Ads Screen (watch_ads_screen.dart)
Current Issues:

No ad preview/placeholder
Button enabled even when limit reached
Missing cooldown timer
No visual feedback during ad load

Recommended Improvements:
dart// ✅ Add cooldown timer and better states
class _WatchAdsScreenState extends State<WatchAdsScreen> {
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  
  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds == 0) timer.cancel();
      });
    });
  }
  
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _cooldownSeconds == 0 && adsWatched < limit
        ? () async {
            await _showAd();
            _startCooldown();
          }
        : null,
      icon: _cooldownSeconds > 0
        ? Text('$_cooldownSeconds s')
        : Icon(Icons.play_circle_fill),
      label: Text(_cooldownSeconds > 0
        ? 'Wait...'
        : 'Watch Ad (+4 coins)'
      ),
    );
  }
}

6. Spin & Win Screen (spin_and_win_screen.dart)
Current Issues:

Wheel animation is good, but rewards distribution unclear
No explanation of probabilities
Missing sound effects
Button text generic

Recommendations:

Add reward probability display (e.g., "70% chance: 5-10 coins")
Show last 5 spin results
Add haptic feedback on spin stop
Celebrate big wins with confetti animation


7. Tic-Tac-Toe Screen (tic_tac_toe_screen.dart)
Strengths: Clean game board, good AI logic
Issues:

Stats (xScore, oScore) are mocked, not real
No coin reward shown until game ends
Missing difficulty levels
No achievement system

Quick Fixes:
dart// Show potential reward upfront
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.green.shade100,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.monetization_on, color: Colors.green.shade700),
      SizedBox(width: 8),
      Text('Win to earn 4 coins!', style: TextStyle(fontWeight: FontWeight.w600)),
    ],
  ),
)

8. Withdraw Screen (withdraw_screen.dart)
CRITICAL ISSUES:
dart// ❌ Form shows all fields at once, overwhelming
TextFormField(controller: _accountNumberController),
TextFormField(controller: _ifscController),
TextFormField(controller: _nameController),
```

**Problems:**
1. No minimum amount calculation shown (10,000 coins = ₹100)
2. UPI/Bank fields shown together (confusing)
3. No explanation of processing time
4. Missing withdrawal history preview

**Recommended Redesign:**

**Step 1: Amount Selection**
```
┌─────────────────────────┐
│ Your Balance: 12,450    │
│                         │
│ Select Amount to Withdraw│
│ ┌─────────────────────┐ │
│ │ [10,000] [₹100]     │ │ ← Preset buttons
│ │ [20,000] [₹200]     │ │
│ └─────────────────────┘ │
│                         │
│ Or enter custom amount  │
│ [_____] coins           │
│                         │
│ 💡 Min: ₹100 (10,000)   │
│ Processing: 48-72 hours │
│                         │
│ [Continue →]            │
└─────────────────────────┘
```

**Step 2: Method Selection**
```
┌─────────────────────────┐
│ Choose Payment Method   │
│                         │
│ ┌───────────────────┐   │
│ │ 📱 UPI            │   │ ← Card with radio
│ │ Instant transfer  │   │
│ │ ○                 │   │
│ └───────────────────┘   │
│                         │
│ ┌───────────────────┐   │
│ │ 🏦 Bank Transfer  │   │
│ │ 2-3 days          │   │
│ │ ○                 │   │
│ └───────────────────┘   │
│                         │
│ [Next]                  │
└─────────────────────────┘
Improved Code:
dart// Multi-step form with PageView
class WithdrawScreen extends StatefulWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Withdraw'),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Controlled navigation
        children: [
          _AmountSelectionPage(),
          _MethodSelectionPage(),
          _DetailsEntryPage(),
          _ConfirmationPage(),
        ],
      ),
    );
  }
}

9. Invite Screen (invite_screen.dart)
Issues:

Referral code not prominent
Share button generic
Referred users list shows IDs instead of names
No visual progress indicators

Recommended Redesign:
┌─────────────────────────┐
│ 🎁 Invite & Earn 500    │ ← Header card
│                         │
│ Your Referral Code      │
│ ┌─────────────────────┐ │
│ │    ABC123           │ │ ← Large, bold
│ │    [Copy] [Share]   │ │
│ └─────────────────────┘ │
│                         │
│ How it works:           │
│ 1️⃣ Friend signs up      │
│ 2️⃣ They use app 3 days  │
│ 3️⃣ You get 500 coins!   │
│                         │
│ Your Referrals (3)      │
│ ┌─────────────────────┐ │
│ │ User A              │ │
│ │ Active: 3/3 days ✅ │ │
│ │ [You earned 500]    │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ User B              │ │
│ │ Active: 1/3 days    │ │
│ │ [●○○] Pending...    │ │
│RetrySContinue│ └─────────────────────┘ │
│                         │
│ [Invite More Friends]   │
└─────────────────────────┘
Improved Code:
dart// ✅ Better referral card with progress visualization
class ReferralUserCard extends StatelessWidget {
  final Map<String, dynamic> referral;
  
  Widget build(BuildContext context) {
    final activeDays = referral['refereeActiveDays'] ?? 0;
    final rewarded = referral['referrerRewarded'] ?? false;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    referral['refereeId'].substring(0, 2).toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${referral['refereeId'].substring(0, 6)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildProgressIndicator(activeDays),
                    ],
                  ),
                ),
                if (rewarded)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, 
                          color: Colors.green.shade700, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '+500',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(int days) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            width: 30,
            height: 6,
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < days ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        SizedBox(width: 8),
        Text(
          '$days/3 days',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

10. Transaction History Screen (transaction_history_screen.dart)
Current Issues:
dart// ❌ Placeholder data, no real Firestore integration
final List<Map<String, dynamic>> transactions = [
  {'type': 'earning', 'amount': 10, 'timestamp': '2025-01-15'},
  // Mock data
];
```

**Problems:**
1. No pagination (will fail with >100 transactions)
2. No date grouping
3. Missing transaction details modal
4. Filter dropdown doesn't persist selection

**Recommended Redesign:**

**Grouped by Date:**
```
┌─────────────────────────┐
│ [All ▼] [Download CSV]  │ ← Filters
│                         │
│ Today                   │
│ ┌─────────────────────┐ │
│ │ 📺 Ad Watched       │ │
│ │ 2:30 PM        +4   │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 🎁 Daily Reward     │ │
│ │ 8:00 AM        +10  │ │
│ └─────────────────────┘ │
│                         │
│ Yesterday               │
│ ┌─────────────────────┐ │
│ │ 🎰 Spin & Win       │ │
│ │ 9:15 PM        +20  │ │
│ └─────────────────────┘ │
│                         │
│ [Load More]             │
└─────────────────────────┘
Improved Implementation:
dart// ✅ Real Firestore query with pagination
class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _transactions = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchTransactions();
      }
    }
  }
  
  Future<void> _fetchTransactions() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    Query query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(20);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _transactions.addAll(snapshot.docs);
      _lastDocument = snapshot.docs.last;
      _isLoading = false;
    });
  }
  
  Widget build(BuildContext context) {
    // Group transactions by date
    final groupedTransactions = _groupByDate(_transactions);
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: groupedTransactions.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedTransactions.length) {
          return Center(child: CircularProgressIndicator());
        }
        
        final date = groupedTransactions.keys.elementAt(index);
        final txns = groupedTransactions[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ...txns.map((txn) => _TransactionTile(txn)).toList(),
          ],
        );
      },
    );
  }
  
  Map<String, List<DocumentSnapshot>> _groupByDate(List<DocumentSnapshot> transactions) {
    final Map<String, List<DocumentSnapshot>> grouped = {};
    for (var txn in transactions) {
      final timestamp = (txn.data() as Map)['timestamp'] as Timestamp?;
      if (timestamp == null) continue;
      
      final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      grouped.putIfAbsent(date, () => []).add(txn);
    }
    return grouped;
  }
}
```

---

#### **11. Profile Screen** (profile_screen.dart)

**Current Issues:**
- Generic list items
- No stats/achievements
- Missing logout confirmation dialog
- No profile picture upload option

**Recommended Redesign:**
```
┌─────────────────────────┐
│                         │
│   [Profile Picture]     │ ← 80x80 avatar
│   John Doe              │
│   john@example.com      │
│                         │
│  ┌─────────────────────┐│
│  │ Stats               ││ ← Cards grid
│  │ Total Earned: ₹25   ││
│  │ Days Active: 12     ││
│  │ Referrals: 3        ││
│  └─────────────────────┘│
│                         │
│  Account                │ ← Section headers
│  ┌───────────────────┐  │
│  │ 📝 Edit Profile   │  │
│  │ 💳 Payment Info   │  │
│  └───────────────────┘  │
│                         │
│  App Settings           │
│  ┌───────────────────┐  │
│  │ ⚙️ Preferences     │  │
│  │ 🔔 Notifications  │  │
│  │ ❓ Help & Support │  │
│  └───────────────────┘  │
│                         │
│  [Logout]               │ ← Danger zone
└─────────────────────────┘
Improved Code:
dart// ✅ Better profile header with stats
class ProfileHeader extends StatelessWidget {
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFFBB86FC)],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
                child: user?.photoURL == null
                  ? Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, size: 18),
                    onPressed: () {
                      // TODO: Image picker
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            user?.displayName ?? 'No Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Earned',
                value: '₹${((user?.totalEarned ?? 0) / 100).toStringAsFixed(2)}',
              ),
              _StatItem(
                label: 'Days',
                value: '${user?.activeDays.length ?? 0}',
              ),
              _StatItem(
                label: 'Referrals',
                value: '${context.watch<UserProvider>().referredUsers.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

12. Settings Screen (settings_screen.dart)
Current Issues:

Only 2 settings (notifications, dark mode)
Dark mode not implemented (just toggle)
No about/version info
Missing data management options

Recommendations:
dart// ✅ Complete settings with sections
class SettingsScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return Scaffold(
      appBar: CustomAppBar(title: 'Settings'),
      body: ListView(
        children: [
          _buildSection('Notifications'),
          SwitchListTile(
            title: Text('Push Notifications'),
            subtitle: Text('Get alerts for earnings'),
            value: settings.notificationsEnabled,
            onChanged: settings.toggleNotifications,
          ),
          SwitchListTile(
            title: Text('Email Updates'),
            subtitle: Text('Weekly earnings summary'),
            value: settings.emailUpdatesEnabled,
            onChanged: settings.toggleEmailUpdates,
          ),
          
          Divider(),
          _buildSection('Appearance'),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Easy on the eyes'),
            value: settings.darkModeEnabled,
            onChanged: settings.toggleDarkMode,
          ),
          
          Divider(),
          _buildSection('Data & Privacy'),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Download My Data'),
            onTap: () => _exportUserData(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete Account', 
              style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDeleteAccount(context),
          ),
          
          Divider(),
          _buildSection('About'),
          ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: Text('Terms of Service'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openUrl('https://example.com/terms'),
          ),
          ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openUrl('https://example.com/privacy'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

🎨 DESIGN SYSTEM RECOMMENDATIONS
Color Palette (Replace generic blues):
dartclass AppColors {
  // Primary
  static const primary = Color(0xFF6200EE);
  static const primaryLight = Color(0xFFBB86FC);
  static const primaryDark = Color(0xFF3700B3);
  
  // Accent
  static const accent = Color(0xFF03DAC6);
  static const accentDark = Color(0xFF018786);
  
  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  
  // Neutrals
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F5);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}
Typography:
dartclass AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
Spacing System:
dartclass AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

---

## 3️⃣ USER EXPERIENCE FLOW ANALYSIS

### 🚀 New User Journey (Current vs Improved)

**❌ CURRENT FLOW (Confusing):**
```
1. Splash (2s) → Generic loading
2. Onboarding (3 screens) → Placeholder images
3. Auth → Google/Email sign-in
4. Referral code? → Hidden in signup form
5. Home → Cluttered list
6. "What do I do?" → No guidance
```

**✅ IMPROVED FLOW (Guided):**
```
1. Splash (2s) → Branded animation
2. Onboarding:
   - "Earn coins easily" (clear illustration)
   - "Invite friends, earn more" (show ₹5 referral)
   - "Withdraw real money" (show UPI/Bank)
3. Auth → Prominent Google button
4. Referral modal (optional):
   "Got a referral code? Enter it now for 200 bonus coins!"
   [Skip] [Enter Code]
5. Home → Daily reward highlighted
6. Tutorial overlay:
   "👋 Welcome! Claim your first 10 coins here ↓"
7. After claim → Show other earning methods with "Try next" hints
```

---

### 🎯 Core User Loops

**Daily Engagement Loop:**
```
Morning:
1. Open app → See daily reward notification
2. Claim 10 coins → Instant feedback animation
3. Check progress: "8/10 ads today"
4. Watch 2 ads → Earn 8 coins
5. Spin wheel → Win 20 coins
6. Total: 38 coins earned in 5 minutes ✅

Evening:
1. Play Tic-Tac-Toe → 3 games = 12 coins
2. Check balance → "You're close to ₹100!"
3. Invite friends → Share code
4. Close app → "Come back tomorrow for +10 coins!"
```

**Withdrawal Journey (Simplified):**
```
Current:
1. Click withdraw → Overwhelming form
2. Fill all fields → Confusion about IFSC
3. Submit → No feedback
4. Wait → No status updates

Improved:
1. See "Withdraw Ready!" badge when balance > 10,000
2. Click → Step 1: Choose amount (presets)
3. Step 2: Select UPI/Bank (clear pros/cons)
4. Step 3: Enter details (autofill saved info)
5. Step 4: Review & confirm
6. Success screen: "Request submitted! Check status in History."
7. Push notification: "Withdrawal approved! ₹100 sent to your UPI."

4️⃣ ADS & MONETIZATION REVIEW
📊 Current Ad Implementation Issues
Problems in ad_provider.dart:

No Ad Frequency Capping:

dart// ❌ User can spam ads if they reload quickly
void showRewardedAd() {
  if (_rewardedAd == null) return;
  _rewardedAd!.show(...); // No cooldown
}

No Ad Failure Recovery:

dart// ❌ If ad fails to load, no retry mechanism
onAdFailedToLoad: (error) {
  _isRewardedAdReady = false; // Just sets flag
  // Missing: Auto-retry after delay, user notification
}

Reward Verification Weakness:

dart// ❌ Coins awarded immediately on callback
onUserEarnedReward: (ad, reward) {
  onAdEarned(reward); // No server-side verification
}

✅ IMPROVED AD STRATEGY
1. Implement Smart Ad Queue System:
dart// 📦 NEW: AdQueueManager
class AdQueueManager {
  final Queue<String> _adQueue = Queue();
  DateTime? _lastAdShown;
  static const MIN_AD_INTERVAL = Duration(seconds: 30);
  static const MAX_QUEUE_SIZE = 3; // Preload 3 ads
  
  bool get canShowAd {
    if (_lastAdShown == null) return true;
    return DateTime.now().difference(_lastAdShown!) > MIN_AD_INTERVAL;
  }
  
  void preloadAds() {
    while (_adQueue.length < MAX_QUEUE_SIZE) {
      _loadNextAd();
    }
  }
  
  Future<void> _loadNextAd() async {
    final adId = await RewardedAd.load(...);
    _adQueue.add(adId);
  }
  
  Future<bool> showNextAd({
    required Function(RewardItem) onRewarded,
    required Function(String) onError,
  }) async {
    if (!canShowAd) {
      onError('Please wait ${_remainingCooldown()} seconds');
      return false;
    }
    
    if (_adQueue.isEmpty) {
      onError('Ad not ready. Loading...');
      await _loadNextAd();
      return false;
    }
    
    final adId = _adQueue.removeFirst();
    // Show ad and handle callbacks
    _lastAdShown = DateTime.now();
    preloadAds(); // Reload queue in background
    return true;
  }
  
  int _remainingCooldown() {
    if (_lastAdShown == null) return 0;
    final elapsed = DateTime.now().difference(_lastAdShown!).inSeconds;
    return max(0, MIN_AD_INTERVAL.inSeconds - elapsed);
  }
}
2. Ad Placement Strategy:
yamlScreen-wise Ad Integration:

Watch Ads Screen:
  - Rewarded ads ONLY
  - Max 10 per day
  - 30s cooldown between ads
  - Show countdown timer

Spin & Win:
  - Rewarded ad before each spin
  - Max 3 spins/day
  - No cooldown (already limited by spins)

Tic-Tac-Toe:
  - Rewarded ad after game ends
  - No daily limit
  - But 30s cooldown applies

Home Screen:
  - Banner ad at bottom (optional, for extra revenue)
  - Non-intrusive, collapses when scrolling

Withdrawal Screen:
  - NO ADS (ruins trust)
3. Ad Revenue Optimization:
dart// 📈 Ad Performance Tracker
class AdAnalytics {
  static Future<void> logAdEvent(String event, Map<String, dynamic> params) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event,
      parameters: {
        ...params,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // Track ad impressions
  static Future<void> onAdImpression(String adType) async {
    await logAdEvent('ad_impression', {'ad_type': adType});
  }
  
  // Track ad completion rate
  static Future<void> onAdCompleted(String adType, bool rewarded) async {
    await logAdEvent('ad_completed', {
      'ad_type': adType,
      'rewarded': rewarded,
    });
  }
  
  // Track ad failures (to optimize ad network)
  static Future<void> onAdFailed(String adType, String errorCode) async {
    await logAdEvent('ad_failed', {
      'ad_type': adType,
      'error_code': errorCode,
    });
  }
}

5️⃣ FIRESTORE OPTIMIZATION IMPLEMENTATION PLAN
🎯 Complete Cache-First Architecture
Step 1: Create Repository Layer
dart// 📁 lib/data/repositories/user_repository.dart
class UserRepository {
  final FirebaseFirestore _firestore;
  final CacheManager _cache;
  final WriteQueue _writeQueue;
  
  UserRepository({
    required FirebaseFirestore firestore,
    required CacheManager cache,
    required WriteQueue writeQueue,
  }) : _firestore = firestore,
       _cache = cache,
       _writeQueue = writeQueue;
  
  // 🔥 SINGLE READ ON APP LAUNCH
  Future<AppUser?> initializeUser(String uid) async {
    // 1. Try cache first (0 reads)
    final cached = await _cache.getCachedUser(uid);
    if (cached != null && !_cache.isCacheExpired(uid)) {
      return cached;
    }
    
    // 2. Cache expired, fetch from Firestore (1 read)
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    
    final user = AppUser.fromFirestore(userDoc);
    await _cache.cacheUser(uid, user);
    
    return user;
  }
  
  // 💾 UPDATE LOCAL CACHE (0 writes to Firestore)
  Future<AppUser> updateUserLocally(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    final currentUser = await _cache.getCachedUser(uid);
    if (currentUser == null) throw Exception('User not found in cache');
    
    // Apply updates to cached user
    final updatedUser = currentUser.copyWithUpdates(updates);
    await _cache.cacheUser(uid, updatedUser);
    
    // Queue write for later batch sync
    _writeQueue.queueUserUpdate(uid, updates);
    
    return updatedUser;
  }
  
  // 📝 BATCH SYNC (Called every 6 hours or on app close)
  Future<void> syncPendingWrites() async {
    await _writeQueue.flushAllWrites(_firestore);
  }
}
Step 2: Implement Write Queue with Persistence
dart// 📁 lib/data/repositories/write_queue.dart
class WriteQueue {
  final SharedPreferences _prefs;
  List<WriteOperation> _queue = [];
  Timer? _syncTimer;
  
  static const QUEUE_KEY = 'pending_writes';
  static const LAST_SYNC_KEY = 'last_sync_time';
  static const SYNC_INTERVAL_HOURS = 6;
  
  WriteQueue(this._prefs) {
    _loadQueueFromStorage();
    _startPeriodicSync();
  }
  
  // Load queue from storage (survives app restart)
  Future<void> _loadQueueFromStorage() async {
    final String? queueJson = _prefs.getString(QUEUE_KEY);
    if (queueJson != null) {
      final List<dynamic> decoded = json.decode(queueJson);
      _queue = decoded
          .map((e) => WriteOperation.fromJson(e))
          .toList();
    }
  }
  
  // Persist queue to storage
  Future<void> _saveQueueToStorage() async {
    final encoded = json.encode(_queue.map((e) => e.toJson()).toList());
    await _prefs.setString(QUEUE_KEY, encoded);
  }
  
  // Add write operation to queue
  void queueUserUpdate(String uid, Map<String, dynamic> updates) {
    _queue.add(WriteOperation(
      type: 'user_update',
      userId: uid,
      data: updates,
      timestamp: DateTime.now(),
    ));
    _saveQueueToStorage();
  }
  
  void queueTransaction(Map<String, dynamic> transaction) {
    _queue.add(WriteOperation(
      type: 'transaction',
      data: transaction,
      timestamp: DateTime.now(),
    ));
    _saveQueueToStorage();
  }
  
  // Start periodic sync (every 6 hours)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      Duration(hours: SYNC_INTERVAL_HOURS),
      (_) async {
        await flushAllWrites(FirebaseFirestore.instance);
      },
    );
  }
  
  // Flush all pending writes in batched operations
  Future<void> flushAllWrites(FirebaseFirestore firestore) async {
    if (_queue.isEmpty) return;
    
    // Aggregate operations by type
    final userUpdates = <String, Map<String, dynamic>>{};
    final transactions = <Map<String, dynamic>>[];
    final referrals = <Map<String, dynamic>>[];
    
    for (var op in _queue) {
      switch (op.type) {
        case 'user_update':
          _mergeUserUpdate(userUpdates, op);
          break;
        case 'transaction':
          transactions.add(op.data);
          break;
        case 'referral':
          referrals.add(op.data);
          break;
      }
    }
    
    // Execute in maximum 3 write operations
    await _executeBatchedWrites(
      firestore,
      userUpdates,
      transactions,
      referrals,
    );
    
    // Clear queue after successful sync
    _queue.clear();
    await _saveQueueToStorage();
    await _prefs.setInt(
      LAST_SYNC_KEY,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  // Merge multiple user updates into one
  void _mergeUserUpdate(
    Map<String, Map<String, dynamic>> userUpdates,
    WriteOperation op,
  ) {
    final uid = op.userId!;
    if (!userUpdates.containsKey(uid)) {
      userUpdates[uid] = {};
    }
    
    // Aggregate increment operations
    for (var entry in op.data.entries) {
      if (entry.value is FieldValue) {
        // Handle FieldValue.increment
        userUpdates[uid]![entry.key] = entry.value;
      } else if (entry.key.contains('.')) {
        // Handle nested updates (e.g., dailyStats.2025-01-15.adsWatched)
        userUpdates[uid]![entry.key] = entry.value;
      } else {
        // Regular