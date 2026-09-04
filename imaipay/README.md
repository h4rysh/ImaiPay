<div align="center">
  <img src="assets/icon.png" alt="ImaiPay Logo" width="120" />
  <h1>ImaiPay</h1>
  <p><strong>Safe and protected payments for everyday life.</strong></p>
  
  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" alt="Firebase" /></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" /></a>
  </p>
</div>

---

## 🛡️ About ImaiPay

ImaiPay is a modern financial application built with Flutter and Firebase, specifically designed to protect vulnerable populations (like seniors) from financial scams. It introduces a **Dual-Role Guardian System**, where a trusted family member or caretaker is securely linked to the primary user's account to oversee and approve high-risk transactions.

### Key Features
* **Dual Roles:** Log in as a **Senior** (primary user) or a **Caretaker/Guardian** (overseer).
* **Escrow Delay:** Transactions can be cancelled within a customizable grace period before funds are moved.
* **Guardian Approval:** High-value or flagged transactions are held in escrow until the Caretaker approves them.
* **Real-Time Wallets:** Sub-second balance updates powered by Firestore streams and robust Cloud Functions.
* **Live-Call Guard (Planned):** Phone permissions check to flag transfers made while on active phone calls (a common scam tactic).

---

## 🏗️ Architecture

ImaiPay uses a strict MVC pattern separated by feature domains. All financial logic is heavily enforced on the backend via Firebase Cloud Functions and Firestore Security Rules.

### Codebase Structure
```
imaipay/
├── lib/
│   ├── core/
│   │   ├── models/       # Data classes (Wallet, Transaction, UserProfile)
│   │   ├── providers/    # State management wrappers
│   │   └── services/     # Firebase SDK & Cloud Function integrations
│   ├── features/
│   │   ├── auth/         # Phone Authentication & Guardian Linking
│   │   └── dashboard/    # Senior & Guardian specific dashboards
│   └── main.dart         # Entrypoint & Routing
├── functions/
│   ├── src/
│   │   ├── transfers/    # Core money movement logic (Escrow, Settle)
│   │   ├── guardian/     # Guardian approval/denial logic
│   │   ├── pairing/      # Secure account linking/unlinking
│   │   └── settings/     # Top-ups and configuration
│   └── index.ts          # Cloud Functions entrypoint
└── firestore.rules       # Strict database security policies
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.0+)
* Node.js (v20+)
* Firebase CLI (`npm install -g firebase-tools`)

### 1. Backend Setup (Firebase Emulators)
ImaiPay is configured out-of-the-box to run completely locally using the Firebase Emulator Suite. No live cloud project is required for development!

```bash
cd functions
npm install
npm run build

# Start the local emulators (Auth, Firestore, Functions)
cd ..
firebase emulators:start
```

### 2. App Setup
Update the emulator host IP address to match your testing environment. Open `lib/main.dart` and modify the `EMULATOR_HOST` environment variable, or run the app with it defined:

```bash
flutter pub get

# For Android Emulator / iOS Simulator (uses 10.0.2.2 or localhost)
flutter run

# For Physical Devices (replace with your Mac/PC's local LAN IP)
flutter run --dart-define=EMULATOR_HOST=192.168.1.xxx
```

---

## 🧪 Testing Scenarios

1. **Top-Up:** Log in as a Caretaker, link a Senior, and tap "Top Up" to add demo funds to their wallet.
2. **Safe Transfer:** Log in as the Senior and send ₹500. It will process normally or enter Escrow (cancelable).
3. **Flagged Transfer:** Log in as the Senior and send a large amount (e.g., ₹50,000). The transaction will be flagged as `REVIEW_REQUIRED`.
4. **Guardian Intervention:** Log back in as the Caretaker to review the flagged transaction and either **Approve** or **Deny** it.

---

## 🔐 Security & Safety First
* **Zero Client-Side Trust:** The Flutter app cannot modify wallet balances directly. All transfers execute inside atomic Firestore transactions within Cloud Functions.
* **Audit Logging:** Every financial event is tracked immutably in an `auditLogs` collection.
* **Rule-Based Permissions:** Firestore Security Rules ensure Caretakers can only view data for Seniors they are explicitly linked to.

<br/>
<div align="center">
  <i>Built with ❤️ for a safer financial future.</i>
</div>
