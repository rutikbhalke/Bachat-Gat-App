import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/models/group.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group Fund & Loan Availability Tests (User Business Rules)', () {
    // -------------------------------------------------------------
    // TEST 1:
    // Savings = ₹20,000, Loans = ₹0, Available = ₹20,000
    // Loan ₹20,000 -> PASS
    // Loan ₹20,001 -> FAIL
    // -------------------------------------------------------------
    test('TEST 1: Savings ₹20,000, Loans ₹0 -> Available ₹20,000. Loan ₹20,000 allowed, ₹20,001 rejected', () {
      const savings = 20000.0;
      const loans = 0.0;
      final available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);

      expect(available, 20000.0);
      expect(CalculationUtils.formatCurrency(available), '₹20,000');

      // Validations
      const validLoan = 20000.0;
      const invalidLoan = 20001.0;
      expect(validLoan <= available, isTrue);
      expect(invalidLoan <= available, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 2:
    // Savings = ₹20,000, Loans = ₹10,000, Available = ₹10,000
    // Loan ₹10,000 -> PASS
    // Loan ₹10,001 -> FAIL
    // Loan ₹30,000 -> FAIL
    // -------------------------------------------------------------
    test('TEST 2: Savings ₹20,000, Loans ₹10,000 -> Available ₹10,000. Loan ₹10,000 allowed, ₹10,001 and ₹30,000 rejected', () {
      const savings = 20000.0;
      const loans = 10000.0;
      final available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);

      expect(available, 10000.0);
      expect(CalculationUtils.formatCurrency(available), '₹10,000');

      expect(10000.0 <= available, isTrue);
      expect(10001.0 <= available, isFalse);
      expect(30000.0 <= available, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 3:
    // Savings = ₹20,000, Loans = ₹20,000, Available = ₹0
    // New loan ₹1 -> FAIL
    // -------------------------------------------------------------
    test('TEST 3: Savings ₹20,000, Loans ₹20,000 -> Available ₹0. Any new loan must be rejected', () {
      const savings = 20000.0;
      const loans = 20000.0;
      final available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);

      expect(available, 0.0);
      expect(CalculationUtils.formatCurrency(available), '₹0');

      expect(1.0 <= available, isFalse);
    });

    // -------------------------------------------------------------
    // TEST 4:
    // Savings = ₹20,000, Loans = ₹10,000, Available = ₹10,000
    // New loan ₹8,000 -> PASS
    // After loan: Loans = ₹18,000, Available = ₹2,000
    // -------------------------------------------------------------
    test('TEST 4: Savings ₹20,000, Loans ₹10,000 -> Disburse ₹8,000 -> Loans ₹18,000, Available ₹2,000', () {
      const savings = 20000.0;
      var loans = 10000.0;
      var available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);
      expect(available, 10000.0);

      const newLoanAmount = 8000.0;
      expect(newLoanAmount <= available, isTrue);

      // Simulate loan disbursement
      loans += newLoanAmount;
      available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);

      expect(loans, 18000.0);
      expect(available, 2000.0);
      expect(CalculationUtils.formatCurrency(loans), '₹18,000');
      expect(CalculationUtils.formatCurrency(available), '₹2,000');
    });

    // -------------------------------------------------------------
    // TEST 5:
    // Savings = ₹20,000, Loans = ₹20,000, Available = ₹0
    // Principal repayment = ₹5,000
    // After repayment: Loans = ₹15,000, Available = ₹5,000
    // -------------------------------------------------------------
    test('TEST 5: Savings ₹20,000, Loans ₹20,000 -> Repay ₹5,000 principal -> Loans ₹15,000, Available ₹5,000', () {
      const savings = 20000.0;
      var loans = 20000.0;
      var available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);
      expect(available, 0.0);

      // Simulate principal repayment
      const principalRepaid = 5000.0;
      loans -= principalRepaid;
      available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);

      expect(loans, 15000.0);
      expect(available, 5000.0);
      expect(CalculationUtils.formatCurrency(loans), '₹15,000');
      expect(CalculationUtils.formatCurrency(available), '₹5,000');
    });

    // -------------------------------------------------------------
    // TEST 6:
    // 2% monthly interest on reducing principal remains strictly untouched
    // Loan = ₹10,000 -> Month 1 interest = ₹200
    // Repay ₹5,000 -> Outstanding = ₹5,000 -> Month 2 interest = ₹100
    // -------------------------------------------------------------
    test('TEST 6: 2% Monthly Interest on reducing principal strictly preserved', () {
      const loanAmount = 10000.0;
      final interestMonth1 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: loanAmount,
        annualRate: 2.0,
      );
      expect(interestMonth1, 200.0);

      final remaining = CalculationUtils.calculateRemainingPrincipal(loanAmount, 5000.0);
      expect(remaining, 5000.0);

      final interestMonth2 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: remaining,
        annualRate: 2.0,
      );
      expect(interestMonth2, 100.0);
    });

    // -------------------------------------------------------------
    // TEST 7:
    // Inconsistency handling: Active loans ₹1,05,555 > Total Savings ₹24,500
    // Available = ₹0 (not negative), inconsistency detected
    // -------------------------------------------------------------
    test('TEST 7: Inconsistent historical data (Loans > Savings) flags inconsistency & keeps Available at ₹0', () {
      const savings = 24500.0;
      const loans = 105555.0;

      final available = CalculationUtils.calculateAvailableFund(totalSavings: savings, outstandingLoans: loans);
      final hasInconsistency = CalculationUtils.hasFundInconsistency(totalSavings: savings, outstandingLoans: loans);

      expect(available, 0.0);
      expect(hasInconsistency, isTrue);
      expect(CalculationUtils.formatCurrency(available), '₹0');
    });

    // -------------------------------------------------------------
    // TEST 8:
    // Model getter integration verification
    // -------------------------------------------------------------
    test('TEST 8: BachatGatGroup getters return correct availableFund and totalGroupAssets', () {
      final group = BachatGatGroup(
        id: 'G1',
        name: 'Shivshahi Bachat Gat',
        managerId: 'M1',
        monthlyTarget: 6000,
        monthlyContributionAmount: 1000,
        totalSavings: 20000.0,
        totalOutstandingLoans: 10000.0,
        totalInterestCollected: 400.0,
        totalFund: 10000.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 18),
      );

      expect(group.availableFund, 10400.0);
      expect(group.availableCash, 10400.0);
      expect(group.totalGroupAssets, 20400.0);
    });
  });
}
