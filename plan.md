I want to build a cross-platform Flutter mobile app (Android + iOS): an Earning app where users earn virtual coins (100 coins = ₹1) and can later withdraw them.
Authentication & backend
* Use Firebase Authentication with Google Sign-In and Email/Password.
* Use Cloud Firestore for all app data and FCM for push notifications. Do not use Firebase Functions or Firebase Hosting.
* Use AdMob for ads (rewarded ads, interstitials as required).
Earning methods
1. Daily reward (one claim per day).
2. Watch rewarded ads — allow up to 10 rewarded ad watches per day.
3. Spin & Win — 3 spins per day, each spin is a rewarded ad.
4. Tic-Tac-Toe game — unlimited plays; after each match (win/lose/draw) user can claim the same coin reward by watching a rewarded ad.
Referral / invites
* Invite screen with referral code flow.
* When a new user redeems a referral code:
   * Referrer receives 500 coins.
   * Referred receives 200 coins.
* Referral reward is credited only after the referred user has used the app on at least 3 separate days.
* Referrer should be able to see how many of their referred users have completed 1, 2, and 3 active days.
Withdrawals
* Withdraw screen with only UPI and Bank Transfer options.
Usage limits
* Per user per day: maximum 5 reads and maximum 3 writes (must be enforced).
Monetization / coin economics
* Calculate coin rewards for each activity based on Indian eCPM, targeting 60% profit margin for the app and 40% payout to users. Provide the coin-per-action calculations and assumptions (eCPM values used, formula, and example).
Deliverables (clear, detailed)
1. A complete feature specification.
2. Detailed data model / Firestore schema (collections, documents, indexes, security rules outline, read/write patterns) that enforces the 5 reads / 3 writes/day limits and referral rules.
3. Ad flow and edge cases (ad failures, reward verification, anti-fraud/duplicate claims).
4. Coin accounting and reconciliation approach to prevent fraud and rounding issues.
5. UI designs (images/mockups) for every screen:
   * Splash screen
   * Onboarding screens
   * Authentication screens (Google Sign-In with referral code entry + Email/Password)
   * Home screen (primary)
   * Invite / Referral screen
   * Profile screen
   * Tic-Tac-Toe game screen
   * Spin & Win screen
   * Watch Ads screen
   * Withdraw screen
   * Any remaining screens (transaction history, settings, support, etc.)
6. Screen flows and navigation structure.
7. Client-side handling (state management recommendation, e.g., Provider / Riverpod / Bloc), and how to minimize Firestore reads/writes to meet limits.
8. Implementation notes for AdMob integration (reward verification), FCM usage, and secure withdrawal processing.
9. Testing checklist and QA scenarios (including referral timing, read/write limit tests, and ad failure cases).
Keep the plan technical and implementation-ready.


Complete Flutter Earning App Specification
1. Executive Summary & Monetization Analysis
Coin Economics & eCPM Calculations
Indian Market Assumptions (2024-2025):

Rewarded Video eCPM: ₹80-120 (avg ₹100)
Interstitial eCPM: ₹40-60 (avg ₹50)
Target: 60% profit margin, 40% user payout

Conversion Rate: 100 coins = ₹1
Activity Rewards Calculation:

Rewarded Ad (Watch Ads screen)

Revenue per ad: ₹100/1000 = ₹0.10
User payout (40%): ₹0.04
Reward: 4 coins per ad
Daily limit: 10 ads = 40 coins


Spin & Win (Rewarded Ad)

Same as above: 4 coins per spin
Daily limit: 3 spins = 12 coins


Tic-Tac-Toe (Rewarded Ad after match)

Same rewarded ad: 4 coins per game
Unlimited plays (ad-gated)


Daily Reward

No ad revenue, pure engagement incentive
Reward: 10 coins (engagement retention)

Referral System

Lifetime value (LTV) based
Avg user LTV estimate: ₹15-20 over 30 days
Referrer: 500 coins (₹5)
Referred: 200 coins (₹2)
Total cost: ₹7 per successful referral
ROI positive if referred user stays 3+ days



Maximum Daily Earning Potential:

Daily reward: 10 coins
Watch ads: 40 coins (10 ads)
Spin & Win: 12 coins (3 spins)
Tic-Tac-Toe: Variable (40+ coins realistic)
Total: ~100+ coins/day (₹1+)


2. Complete Feature Specification
2.1 Core Features
Authentication:

Google Sign-In (primary)
Email/Password (secondary)
Referral code entry during signup
Firebase Authentication integration

Earning Mechanisms:

Daily Reward: 10 coins, once per 24 hours
Watch Ads: 4 coins per ad, 10/day limit
Spin & Win: 4 coins per spin, 3/day limit, each spin requires rewarded ad
Tic-Tac-Toe: 4 coins per game (after ad), unlimited

Referral System:

Unique 6-character referral code per user
Referrer: 500 coins (after referee completes 3 active days)
Referee: 200 coins (immediately after signup)
Dashboard showing referred users' progress (1/3, 2/3, 3/3 days)

Withdrawal:

Minimum: 10,000 coins (₹100)
Methods: UPI, Bank Transfer
Processing: Manual review (48-72 hours)
Transaction history

Usage Limits (Anti-Abuse):

5 Firestore reads per user per day
3 Firestore writes per user per day
Enforced via Firestore security rules + client tracking


3. Detailed Firestore Data Model
3.1 Collections Structure
/users/{userId}
  - email: string
  - displayName: string
  - photoURL: string
  - createdAt: timestamp
  - referralCode: string (unique, indexed)
  - referredBy: string (referral code, nullable)
  - coinBalance: number (default: 0)
  - totalEarned: number
  - totalWithdrawn: number
  - activeDays: array<string> (["2025-01-15", "2025-01-16", ...])
  - lastActiveDate: string (YYYY-MM-DD)
  - dailyStats: map
    - date: string (YYYY-MM-DD)
    - readsCount: number (0-5)
    - writesCount: number (0-3)
    - dailyRewardClaimed: boolean
    - adsWatched: number (0-10)
    - spinsUsed: number (0-3)
    - tictactoeGames: number
  - withdrawalInfo: map
    - upiId: string (nullable)
    - bankAccount: string (nullable)
    - bankIfsc: string (nullable)
    - accountHolder: string (nullable)

/transactions/{transactionId}
  - userId: string (indexed)
  - type: string ("earning" | "withdrawal")
  - subType: string ("daily_reward" | "ad" | "spin" | "tictactoe" | "referral" | "upi" | "bank")
  - amount: number (positive for earning, negative for withdrawal)
  - timestamp: timestamp (indexed)
  - status: string ("pending" | "completed" | "failed")
  - metadata: map (ad details, referral info, withdrawal details)

/referrals/{referralId}
  - referrerId: string (indexed)
  - refereeId: string (indexed)
  - refereeActiveDays: number (0-3)
  - referrerRewarded: boolean
  - refereeRewarded: boolean
  - createdAt: timestamp
  - completedAt: timestamp (nullable)

/withdrawals/{withdrawalId}
  - userId: string (indexed)
  - amount: number
  - method: string ("upi" | "bank")
  - details: map
  - status: string ("pending" | "processing" | "completed" | "rejected")
  - requestedAt: timestamp
  - processedAt: timestamp (nullable)
  - adminNotes: string (nullable)

/app_config/settings (single document)
  - minWithdrawalCoins: number (10000)
  - coinsPerRupee: number (100)
  - dailyReadLimit: number (5)
  - dailyWriteLimit: number (3)
  - dailyAdLimit: number (10)
  - dailySpinLimit: number (3)
  - rewards: map
    - dailyReward: number (10)
    - adReward: number (4)
    - spinReward: number (4)
    - tictactoeReward: number (4)
    - referrerBonus: number (500)
    - refereeBonus: number (200)
```

### 3.2 Composite Indexes Required
```
Collection: transactions
- userId (Ascending) + timestamp (Descending)
- type (Ascending) + status (Ascending) + timestamp (Descending)

Collection: referrals
- referrerId (Ascending) + createdAt (Descending)
- refereeId (Ascending)


3.4 Read/Write Optimization Strategy
you don't have to write codes to tell the app how it should work and i need some changes to the read and write optimization ,Reads
* Single Full Read at App Launch: Load all essential user and app data (profile, config, daily stats, referrals, etc.) in one combined read operation during startup.
* Local Caching: Cache all fetched data locally (using Hive or SharedPreferences) and serve from cache throughout the session.
* Config Refresh: Update `app_config` weekly or when forced via Firebase Remote Config.
* Session-Level Data: Maintain user session data in memory; no intermediate Firestore reads during regular app use.
* Read-Only When Required: Perform Firestore reads only if the local cache is outdated or user triggers a hard refresh (e.g., manual sync).
Writes
* Aggregated Daily Writes (Max 3 per Day): All user actions (ads watched, spins, game results, referrals, etc.) are logged locally first. Data is synced to Firestore only three times per day, with approximately 6-hour gaps (configurable via Firebase Remote Config).
* Batching Strategy:
   * Combine all pending coin updates, stats, and activity logs into one batched write.
   * Ensure `dailyStats` is updated only once per action type per sync cycle.
* Transactional Safety: Use Firestore transactions only for critical updates like coin balance adjustments(even the transaction data must also be sent using the daily 3 write along all the other write(no special treatment)).
* Smart Write Queue: Maintain an in-memory queue of pending writes and flush based on:
   * Time interval (every 6 hours, configurable, and the number or writes i can allocate to user can be configurable via firebase remote config)
   * App close or logout event
   * Manual sync trigger
* Write Tracking: Track write count locally per day; persist the counter to Firestore during the final daily sync to maintain integrity.
Daily Limit Enforcement:

Client-side: Track reads/writes in SharedPreferences
Server-side: Security rules validate based on dailyStats
Reset at midnight (UTC+5:30 IST)

4. Ad Integration & Edge Cases
4.1 AdMob Integration Flow
Setup:
yaml# pubspec.yaml
dependencies:
  google_mobile_ads: ^5.0.0
  
# App IDs
Android: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
iOS: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX

# Ad Unit IDs (Test during development)
Rewarded Ad: ca-app-pub-3940256099942544/5224354917 (test)
Interstitial: ca-app-pub-3940256099942544/1033173712 (test)
Rewarded Ad Flow:
dart1. User triggers action (Watch Ad / Spin / Game Complete)
2. Check daily limit (local + Firestore)
3. Load RewardedAd
4. Show ad
5. On ad rewarded callback:
   - Verify server-side (timestamp, user ID)
   - Update coin balance (Firestore transaction)
   - Create transaction record
   - Update daily stats
6. Handle failures (show error, allow retry)

4.2 Edge Cases & Anti-Fraud
Ad Failures:

No internet: Show error, allow retry after connection
Ad not loaded: Pre-load ads in background, show loading state
Ad closed early: No reward, don't count toward limit
Multiple rapid clicks: Debounce buttons (2-second cooldown)

Reward Verification:

Server-side validation via Firestore security rules
Check timestamp (prevent replays)
Verify user hasn't exceeded daily limit
Use Firestore transactions for coin updates (atomic)

Duplicate Claims Prevention:

Daily reward: Check lastActiveDate and dailyRewardClaimed
Spin & Win: Track spinsUsed in dailyStats
Watch Ads: Track adsWatched count
Tic-Tac-Toe: No limit, but rate-limited by ad availability

Fraud Detection:

Track unusual patterns (too many games in short time)
Limit withdrawals to verified accounts (email verified)
Manual review for first withdrawal
Flag users with referral abuse (too many refs from same IP - future enhancement)


5. Coin Accounting & Reconciliation
5.1 Double-Entry System
Every coin transaction creates:

User balance update (creditBalance field)
Transaction record (audit trail)
totalEarned or totalWithdrawn increment

Transaction Flow:
dart// Example: Award coins
Future<void> awardCoins(String userId, int amount, String subType) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
  
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final userDoc = await transaction.get(userRef);
    final currentBalance = userDoc.data()?['coinBalance'] ?? 0;
    final currentEarned = userDoc.data()?['totalEarned'] ?? 0;
    
    transaction.update(userRef, {
      'coinBalance': currentBalance + amount,
      'totalEarned': currentEarned + amount,
    });
    
    transaction.set(transactionRef, {
      'userId': userId,
      'type': 'earning',
      'subType': subType,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
  });
}


5.2 Reconciliation Logic
Daily:

Sum all transactions for user
Compare with coinBalance + totalWithdrawn
Alert on mismatches

Withdrawal Process:

Check minimum balance (10,000 coins)
Create withdrawal request (status: pending)
Deduct coins immediately (prevent double withdrawal)
Admin processes manually
Update status to completed/rejected
If rejected, refund coins

7. Screen Flows & Navigation Structure
7.1 Navigation Architecture
App Launch
├── Splash Screen (2 seconds)
└── First Time User Check
    ├── YES → Onboarding Flow
    │   ├── Onboarding 1 (Earn Coins)
    │   ├── Onboarding 2 (Referrals)
    │   ├── Onboarding 3 (Withdrawals)
    │   └── Authentication
    │       ├── Google Sign-In → Referral Code Entry (Optional) → Home
    │       └── Email/Password → Referral Code Entry (Optional) → Home
    │
    └── NO → Check Authentication
        ├── Authenticated → Home Screen
        └── Not Authenticated → Login Screen

Home Screen (Bottom Navigation)
├── Home Tab ⭐
│   ├── Daily Reward Modal
│   ├── Watch Ads Screen
│   ├── Spin & Win Screen
│   ├── Tic-Tac-Toe Game
│   └── Withdraw Screen
│
├── Invite Tab
│   ├── Referral Dashboard
│   └── Share Options
│
├── History Tab
│   ├── All Transactions
│   ├── Filter by Type
│   └── Transaction Details
│
└── Profile Tab
    ├── Edit Profile
    ├── Payment Methods
    ├── Settings
    ├── Help & Support
    └── Logout
```

### 7.2 User Flows

**First-Time User Flow:**
```
1. Splash → Onboarding (3 screens) → Google/Email Auth
2. Optional: Enter Referral Code (200 coins bonus)
3. Home Screen Tutorial (highlight daily reward)
4. Claim First Daily Reward (10 coins)
5. Watch First Ad Tutorial
```

**Daily User Flow:**
```
1. App Open → Home Screen
2. Check Daily Reward Availability
3. Claim Daily Reward (if available)
4. Explore Earning Options
5. Watch Ads / Spin / Play Games
6. Check Balance & Withdrawal Eligibility
```

**Withdrawal Flow:**
```
1. Home → Withdraw Button (or Profile → Payment Methods)
2. Select Method (UPI/Bank)
3. Enter Details & Amount
4. Confirm Withdrawal
5. Request Submitted (Pending Status)
6. Email/Push Notification on Status Change
7. View in Transaction History


8. State Management & Client-Side Architecture
8.1 Recommended: Provider + ChangeNotifier
Why Provider:

Simple, Flutter-team recommended
Minimal boilerplate
Good for this app's complexity level
Easy Firebase integration