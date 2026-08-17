# Bachat-Gat App Implementation Plan — Localization & Firebase Backend

This plan outlines the steps to add Marathi/English localization and migrate the application from static/local storage to a full Firebase backend.

## User Review Required

> [!IMPORTANT]
> - **Firebase Configuration:** You will need to provide the `google-services.json` file for Android after I set up the code structure, or I will provide instructions on how to generate it using FlutterFire CLI.
> - **Phone Authentication:** A real device or Firebase emulator is needed to test SMS verification.

## Proposed Changes

### Phase 1: Localization & Language Switcher

Implement official Flutter localization and add a language selector to the Dashboard.

#### [MODIFY] [pubspec.yaml](file:///D:/StudioProjects/Bachat-Gat-App/pubspec.yaml)
- Add `flutter_localizations` dependency.
- Enable `generate: true` for localization.

#### [NEW] [l10n.yaml](file:///D:/StudioProjects/Bachat-Gat-App/l10n.yaml)
- Configure localization paths and class name.

#### [NEW] [app_en.arb](file:///D:/StudioProjects/Bachat-Gat-App/lib/l10n/app_en.arb)
- English translations for all dashboard strings.

#### [NEW] [app_mr.arb](file:///D:/StudioProjects/Bachat-Gat-App/lib/l10n/app_mr.arb)
- Marathi translations for all dashboard strings.

#### [NEW] [locale_provider.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/providers/locale_provider.dart)
- Manage app locale state and persist selection using `SharedPreferences`.

#### [MODIFY] [app.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/app/app.dart)
- Integrate `LocalizationsDelegates` and `supportedLocales`.
- Wrap with `Consumer<LocaleProvider>` to react to language changes.

#### [MODIFY] [dashboard_screen.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/screens/dashboard/dashboard_screen.dart)
- Add the language selector widget in the header.
- Replace hardcoded strings with `AppLocalizations`.

---

### Phase 2: Firebase Integration

Set up Firebase dependencies and core services.

#### [MODIFY] [pubspec.yaml](file:///D:/StudioProjects/Bachat-Gat-App/pubspec.yaml)
- Add `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`.

#### [NEW] [firebase_service.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/services/firebase_service.dart)
- Centralized Firebase initialization and reference management.

---

### Phase 3: Authentication & User Profile

Implement Phone Number Authentication and manager profiles.

#### [NEW] [auth_repository.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/repositories/auth_repository.dart)
- Logic for phone number verification and sign-in.

#### [NEW] [login_screen.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/screens/auth/login_screen.dart)
- Modern UI for phone number input and OTP verification.

---

### Phase 4: Data Migration to Firestore

Migrate Members, Savings, Loans, and Repayments to Firestore.

#### [NEW] [group_repository.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/repositories/group_repository.dart)
- CRUD operations for Groups and Members in Firestore.

#### [NEW] [transaction_repository.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/repositories/transaction_repository.dart)
- Logic for recording Savings, Loans, and Repayments with Firestore transactions.

#### [MODIFY] [dashboard_screen.dart](file:///D:/StudioProjects/Bachat-Gat-App/lib/screens/dashboard/dashboard_screen.dart)
- Bind UI to real-time Firestore streams for totals and progress.

---

### Phase 5: Security & Optimization

#### [NEW] [firestore.rules](file:///D:/StudioProjects/Bachat-Gat-App/firestore.rules)
- Production-ready security rules ensuring managers only access their own group data.

## Verification Plan

### Automated Tests
- `flutter test` to verify calculation logic in models.
- Mock Firebase for repository testing.

### Manual Verification
1. **Localization:** Switch to Marathi and verify all Dashboard text updates correctly. Restart app to verify persistence.
2. **Auth:** Perform phone login and verify manager profile creation in Firestore.
3. **Data:** Add a member and saving, verify they appear in Firestore and reflect on the Dashboard real-time.
4. **Security:** Attempt to access data from another `groupId` using a modified client and verify it fails (via rules).
