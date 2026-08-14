# Redesign Bachat-Gat-App into Modern Fintech Application

Redesign the existing project into a modern, functional fintech-style app for Bachat Gat (Self-Help Group) management.

## User Review Required

> [!IMPORTANT]
> The current project has empty directories for most features. I will be creating the foundational models and services first to support the UI.

> [!NOTE]
> I will use the existing `AppColors` and `AppTheme` but will extend them if needed to support the fintech aesthetic.

## Proposed Changes

### [Models]

#### [NEW] [member.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/models/member.dart)
Model for group members.
#### [NEW] [savings.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/models/savings.dart)
Model for tracking monthly savings.
#### [NEW] [loan.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/models/loan.dart)
Model for loans with interest calculation logic.
#### [NEW] [transaction.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/models/transaction.dart)
Unified transaction model for history.

---

### [Services]

#### [NEW] [finance_service.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/services/finance_service.dart)
Logic for interest calculation and fund management.
#### [NEW] [storage_service.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/services/storage_service.dart)
Persistence using `shared_preferences`.

---

### [Screens]

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/dashboard/widgets/dashboard_screen.dart)
Update dashboard with:
- Total group savings, current month savings.
- Outstanding loans, interest earned, net cash.
- Recent transactions and pending payments.
#### [NEW] [members_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/members/members_screen.dart)
List and add members.
#### [NEW] [savings_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/savings/savings_screen.dart)
Detailed savings view with historical tracking.
#### [NEW] [loans_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/loans/loans_screen.dart)
Loan management and repayment tracking.
#### [NEW] [add_transaction_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/transactions/add_transaction_screen.dart)
Single entry point for adding data.
#### [NEW] [reports_screen.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/screens/reports/reports_screen.dart)
Financial summaries and growth charts.

---

### [Widgets]

#### [NEW] [app_navigation_bar.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/widgets/navigation/app_navigation_bar.dart)
Reusable modern bottom navigation.
#### [NEW] [summary_card.dart](file:///C:/Users/Saideep/StudioProjects/Bachat-Gat-App/lib/widgets/cards/summary_card.dart)
Reusable fintech-style cards for metrics.

## Verification Plan

### Automated Tests
- Unit tests for loan interest calculation (`loan_test.dart`).
- Model serialization tests.

### Manual Verification
- Verify interest calculation matches the example provided:
  - Opening: 50,000, Interest: 2% (1,000), Payment: 6,000 -> Remaining: 45,000.
- Check navigation between all 5 main sections.
- Ensure "Savings History" correctly retains previous amounts when monthly contribution changes.
